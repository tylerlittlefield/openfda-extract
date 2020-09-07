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

# drop all tables before rewriting new tables # <--- Uncomment the line below, commented out to avoid deleting all tables by accident
# drop_all_tables(con)

# fetch links json file
openfda_device_links <- fetch_adverse_event_links()

# get config
config <- config_adverse_events(openfda_device_links[18])

# download data
data <- download_adverse_events(config)

# raw
raw <- prepare_raw(data, config)

# tables
adverse_events <- prepare_adverse_events(raw)
adverse_events.patient <- prepare_patient(raw)
adverse_events.remedial_action <- prepare_remedial_action(raw)
adverse_events.mdr_text <- prepare_mdr_text(raw)
adverse_events.type_of_report <- prepare_type_of_report(raw)
adverse_events.product_problems <- prepare_product_problems(raw)
adverse_events.source_type <- prepare_source_type(raw)
adverse_events.device <- prepare_device(raw)

# write tables
write_table(con, adverse_events, "adverse_events")
write_table(con, adverse_events.patient, "adverse_events.patient")
write_table(con, adverse_events.remedial_action, "adverse_events.remedial_action")
write_table(con, adverse_events.mdr_text, "adverse_events.mdr_text")
write_table(con, adverse_events.type_of_report, "adverse_events.type_of_report")
write_table(con, adverse_events.product_problems, "adverse_events.product_problems")
write_table(con, adverse_events.source_type, "adverse_events.source_type")
write_table(con, adverse_events.device, "adverse_events.device")
