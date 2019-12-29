Personal Website
===

## Development

### Dependencies

* [Rust](https://www.rust-lang.org/) - see `Cargo.toml` for details.

### Build and Run

`cargo build` and `cargo run` work as in a typical Rust app.

By default the web server will run on port `8080`.
The `PORT` environment variable can override that.

To run in watch mode, restarting the server on code changes, first install helpers:
```
cargo install systemfd cargo-watch
```

Then run this command:
```
systemfd --no-pid -- cargo watch -x run
```

To build CSS:
`yarn build`

## Testing

To build the test DB:

```
createdb website_test
```

Migrate it:
```
DATABASE_URL=postgres://localhost/website_test diesel migration run
```

## Deployment

The backend server is hosted on [Heroku](https://www.heroku.com/).
