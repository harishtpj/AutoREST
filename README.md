# 🌐 AutoREST
[![made-with-ruby](https://img.shields.io/badge/Made%20with-Ruby-red)](https://www.ruby-lang.org)

Generate full-featured API servers for your database tables in seconds.

# ℹ About
AutoREST is a database-agnostic RESTful API generator for Ruby. With just your database credentials, it scaffolds a live API server supporting CRUD operations — no Rails, no boilerplate.

**Supported Databases**:

* SQLite
* MySQL
* PostgreSQL
* Oracle

# ✨ Features

* 🛠 Generates RESTful APIs from your database schema
* 🔌 Pluggable DB adapter system
* 🎛 CLI interface powered by [Thor](https://github.com/rails/thor)
* 🗃 Supports major relational DBs via corresponding gems
* 🔥 Runs on Puma + Rack

# 🚀 Installation
Add this line to your application's Gemfile:

```ruby
gem 'autorest'
```

And then execute:

```bash
$ bundle install
```

Or install it as a gem:

```bash
$ gem install autorest
```
> Note: Depending on the DB you use, you may need to install additional gems manually:
>  * `sqlite3`
>  * `mysql2`
>  * `pg`
>  * `ruby-oci8`

# 🏃🏻‍♀️ Quickstart
To get your hand on AutoREST, run:

```bash
autorest boot sqlite://[path/to/sqlite.db]/[table_name]
```

If you want to try with MySQL/PostgreSQL/Oracle, run:

```bash
autorest boot mysql://[username]:[password]@[host]:[port]/[database]/[table_name]
```

for PostgreSQL (or) Oracle, use `pg://` (or) `orcl://` respectively instead of `mysql://`

Now you can access the server at `http://localhost:7914`

# 🖥 CLI usage
1. Via Interactive CLI

```bash
$ autorest new
```

2. Via YAML config file

```bash
$ autorest server <path/to/config>.yml
```

3. Via DSN

```bash
$ autorest boot mysql://[username]:[password]@[host]:[port]/[database]/[table_name]
```

For more information visit [AutoREST documentation](https://www.rubydoc.info/gems/autorest).

# 📦 Configuration example
```yaml
db:
  kind: mysql # sqlite, mysql, pg, orcl
  host: localhost
  port: 3306
  user: root
  passwd: secret
  name: mydb # for sqlite: path/to/sqlite.db, for oracle: SID
  tables: [users, posts]

server:
  host: 127.0.0.1
  port: 8080
```

# 🌐 API endpoints
Once the server is running, you can access the following RESTful API endpoints for the selected tables:

* `GET /<table>` - Returns all rows from table
* `GET /<table>/:id` - Returns a single row by ID (or any primary key)
* `POST /<table>` - Creates a new row in table
* `PUT /<table>/:id` - Updates an existing row by ID (or any primary key)
* `PATCH /<table>/:id` - Updates an existing row by ID (or any primary key)
* `DELETE /users/:id` - Deletes a user by ID

The `PATCH` method simply allows one to update a subset of the columns, whereas the `PUT` method allows one to update all columns.

# ✍🏻 Contributing
Contributions are welcome! While the basic functionality of this project works, there is a lot of room for improvement.  If you have any suggestions or find any bugs, please [open an issue](https://github.com/harishtpj/AutoREST/issues/new/choose) or [create a pull request](https://github.com/harishtpj/AutoREST/pulls).

# 📝 License

#### Copyright © 2025 [M.V.Harish Kumar](https://github.com/harishtpj). <br>

#### This project is [MIT](https://github.com/harishtpj/AutoREST/blob/0341e153b1a8a1df139ff7225cb5f997818db89b/LICENSE) licensed.