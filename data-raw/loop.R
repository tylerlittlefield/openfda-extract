library(jsonlite)
library(dplyr, warn.conflicts = FALSE)
library(tidyr)
library(purrr, warn.conflicts = FALSE)
library(DBI)
library(future)

plan(multicore)

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

# drop all tables before rewriting new tables # <--- Uncomment the line below, commented out to avoid deleting all tables by accident
drop_all_tables(con)

# fetch links json file
openfda_device_links <- fetch_adverse_event_links()

# refresh the database
refresh_db(rev(openfda_device_links))
