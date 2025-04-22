# Test App: Go + HTMX Demo for MongoDB Sharding

A minimal Go web application using HTMX to interact with a MongoDB sharded cluster. You can insert, list, delete documents, and view per‑shard execution stats via a simple web interface.

## Directory Structure

```
.
├── go.mod
├── go.sum
├── main.go
├── static
│   └── styles.css            # Basic CSS
└── templates
    ├── base.html             # Layout with HTMX and navigation
    ├── index.html            # Home page
    ├── docs.html             # List & add/remove documents
    └── shards.html           # Shard stats panel
```

## Prerequisites

- Go installed
- MongoDB sharded cluster running (e.g. via parent Vagrant setup)

## Installation

1. Clone or enter the `test-app` folder inside the main repo.
2. Download dependencies:
   ```bash
   go mod download
   ```

## Configuration

Edit the connection URI in `main.go` if your cluster endpoint, credentials, or ports differ. By default it uses:

```go
uri := "mongodb://mongoAdmin:hackable_pwd@192.168.56.13:27017/?authSource=admin"
```

## Running

Start the server:

```bash
go run main.go
```

Then visit:  
http://127.0.0.1:7777

## Features

- **Home** (`/`) — Static landing page.
- **Docs** (`/docs`) —
  - **GET**: lists all documents in `testdb.testcollection`.
  - **POST**: add a new document (via HTMX form submission).
  - **DELETE**: remove a document by ID (HTMX `hx-delete`).

- **Shards** (`/shards`) — uses MongoDB `explain` with `executionStats` to show how many documents each shard returned.

All dynamic interactions use HTMX (attributes in the templates) to swap content without full-page reloads.

## Templates Overview

- **base.html**: common header, HTMX import, navigation bar.
- **index.html**: simple welcome page.
- **docs.html**: table of documents with inline add/delete.
- **shards.html**: list of shard names and their returned counts.

## License

This test app inherits the main project’s MIT license. Feel free to adapt or extend it.


## Thanks!

Thanks again! 
Made by [Javier Santos](https://github.com/santos-404) and [Josué Rodríguez](https://github.com/JosueRodLop) 
