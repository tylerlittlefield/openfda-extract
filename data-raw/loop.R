library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(DBI)

# credentials
dw <- config::get("datawarehouse")

# connect to db
con <- DBI::dbConnect(
  odbc::odbc(),
  Driver = dw$driver,
  Server = dw$server,
  Database = dw$database,
  UID = dw$uid,
  PWD = dw$pwd,
  Port = dw$port
)

# source functions
source("R/utils.R")

# drop all tables before rewriting new tables
# drop_all_tables(con)

# fetch links json file
openfda_device_links <- fetch_adverse_event_links()

# refresh the database
refresh_db(openfda_device_links[18:175])
