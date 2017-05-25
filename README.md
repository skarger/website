Personal Website
==

## Setup

### System dependencies
* Ruby version: 2.4.1
* Postgres 9.6 with PostGIS extension enabled. On Mac I recommend [Postgres.app](https://postgresapp.com/).
* Elm
* Yarn

### Database creation
```
$ psql
=# CREATE ROLE website WITH SUPERUSER PASSWORD 'website';
=# \q

$ rails db:create
$ rails db:gis:setup
$ rails db:migrate
```

### Run Tests
```
$ rspec
```

### Deployment
```
git push origin master
```
