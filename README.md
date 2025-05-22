# AutoREST
[![made-with-ruby](https://img.shields.io/badge/Made%20with-Ruby-red)](https://www.ruby-lang.org)

Generate full-featured API servers for your database tables in seconds.

# About
This project aims to provide a simple way to generate RESTful APIs for your database tables with mininal effort. Just enter the database connection details and let AutoREST do the rest.

# Features
- Supports major databases (SQLite, MySQL, PostgreSQL, Oracle)
- Can serve multiple tables at once

# Installation
This tool is available as a Ruby gem. To install it, run:

```bash
gem install autorest
```

The tool comes with a powerful CLI that is used to interactively create your restful APIs.

# Quickstart
To get your hand on AutoREST, run:

```bash
autorest boot sqlite://[path/to/sqlite.db]/[table_name]
```

If you want to try with MySQL/PostgreSQL/Oracle, run:

```bash
autorest boot mysql://[username]:[password]@[host]:[port]/[database]/[table_name]
```

for PostgreSQL (or) Oracle, use `pg://` (or) `orcl://` respectively instead of `mysql://`

Access the server at `http://localhost:7914`

# Contributing
Contributions are welcome! While the basic functionality of this project works, there is a lot of room for improvement.  If you have any suggestions or find any bugs, please [open an issue](https://github.com/harishtpj/AutoREST/issues/new/choose) or [create a pull request](https://github.com/harishtpj/AutoREST/pulls).

# License

#### Copyright © 2025 [M.V.Harish Kumar](https://github.com/harishtpj). <br>
#### This project is [MIT](https://github.com/harishtpj/AutoREST/blob/0341e153b1a8a1df139ff7225cb5f997818db89b/LICENSE) licensed.