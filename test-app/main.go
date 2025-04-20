package main

import (
    "context"
    "html/template"
    "log"
    "net/http"
    "time"

    "go.mongodb.org/mongo-driver/bson"
    "go.mongodb.org/mongo-driver/bson/primitive"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
)

// This is the model 
type Doc struct {
    ID   primitive.ObjectID `bson:"_id,omitempty"`
    Name string             `bson:"name"`
}

var (
    tpl       *template.Template
    coll      *mongo.Collection
    ctx       = context.Background()
    baseCtx   context.Context
)

func init() {
    tpl = template.Must(template.ParseGlob("templates/*.html"))

    uri := "mongodb://mongoAdmin:hackable_pwd@192.168.56.13:27017/?authSource=admin"
    clientOpts := options.Client().ApplyURI(uri)

    // A little timeout. Be patient :D
    var cancel context.CancelFunc
    baseCtx, cancel = context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    client, err := mongo.Connect(baseCtx, clientOpts)
    if err != nil {
        log.Fatal("mongo connect:", err)
    }
    coll = client.Database("testdb").Collection("testcollection")
}

func main() {
    http.HandleFunc("/", indexHandler)
    http.HandleFunc("/docs", docsHandler)
    http.HandleFunc("/shards", shardPanelHandler)
    log.Println("Listening on http://127.0.0.1:7777")
    log.Fatal(http.ListenAndServe(":7777", nil))
}

// Renders the full page
func indexHandler(w http.ResponseWriter, r *http.Request) {
    data := struct{ Title string }{"Mongo shard | Aplicación para tests"}
    if err := tpl.ExecuteTemplate(w, "base.html", data); err != nil {
        http.Error(w, err.Error(), 500)
    }
}

func docsHandler(w http.ResponseWriter, r *http.Request) {
    switch r.Method {
    case "GET":
        cur, err := coll.Find(r.Context(), bson.D{})
        if err != nil {
            http.Error(w, err.Error(), 500)
            return
        }
        defer cur.Close(r.Context())

        var docs []Doc
        if err := cur.All(r.Context(), &docs); err != nil {
            http.Error(w, err.Error(), 500)
            return
        }
        tpl.ExecuteTemplate(w, "docs.html", docs)

    case "POST":
        if err := r.ParseForm(); err != nil {
            http.Error(w, err.Error(), 400)
            return
        }
        name := r.FormValue("name")
        res, err := coll.InsertOne(r.Context(), bson.D{{Key: "name", Value: name}})
        if err != nil {
            http.Error(w, err.Error(), 500)
            return
        }
        newDoc := Doc{ID: res.InsertedID.(primitive.ObjectID), Name: name}
        tpl.ExecuteTemplate(w, "docs.html", []Doc{newDoc})

    case "DELETE":
        id := r.URL.Query().Get("id")
        objID, err := primitive.ObjectIDFromHex(id)
        if err != nil {
            http.Error(w, "Invalid ID", 400)
            return
        }

        _, err = coll.DeleteOne(r.Context(), bson.M{"_id": objID})
        if err != nil {
            http.Error(w, err.Error(), 500)
            return
        }

        w.WriteHeader(http.StatusOK)

    default:
        http.Error(w, "Method not allowed", 405)
    }
}

func shardPanelHandler(w http.ResponseWriter, r *http.Request) {
    // Ask Mongo for execution stats
    explainCmd := bson.D{
        {"explain", bson.D{
            {"find", coll.Name()},
            {"filter", bson.D{}},
        }},
        {"verbosity", "executionStats"},
    }

    var result bson.M
    if err := coll.Database().RunCommand(r.Context(), explainCmd).Decode(&result); err != nil {
        http.Error(w, "Explain error: "+err.Error(), 500)
        return
    }

    // Map shard -> count
    stats := make(map[string]int)

    execStats := result["executionStats"].(bson.M)
    shards := execStats["executionStages"].(bson.M)["shards"].(primitive.A)

    for _, shard := range shards {
        shardMap := shard.(bson.M)
        shardName := shardMap["shardName"].(string)
        nReturned := int(shardMap["executionStages"].(bson.M)["nReturned"].(int32))
        stats[shardName] += nReturned
    }

    // Render as list
    tpl.ExecuteTemplate(w, "shards.html", stats)
}

