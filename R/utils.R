config_adverse_events <- function(link) {
  uz_file <- gsub(".zip$", "", basename(link))
  quarter <- sub("/.*", "", gsub("https://download.open.fda.gov/device/event/", "", link))
  part <- gsub("-of-", "-", gsub("device-event-|.json", "", uz_file))
  
  list(
    raw = link,
    uz_file = uz_file,
    quarter = quarter,
    part = part,
    id_prefix = paste0(quarter, "-", part)
  )
}

download_adverse_events <- function(config) {
  temp <- tempfile()
  download.file(config$raw, temp, quiet = TRUE)
  data <- fromJSON(
    txt = unz(temp, config$uz_file), 
    flatten = TRUE, 
    simplifyVector = TRUE, 
    simplifyDataFrame = TRUE
  )
  unlink(temp)
  data
}

fetch_adverse_event_links <- function() {
  openfda_links <- fromJSON("https://api.fda.gov/download.json")
  openfda_device_links <- openfda_links$results$device$event$partitions$file
  openfda_device_links[grepl("q", openfda_device_links)]
}

prepare_raw <- function(.data, config) {
  .data$results %>% 
    as_tibble() %>% 
    mutate(id = paste0(config$id_prefix, "-", row_number())) %>% 
    mutate_if(is.list, function(col) map_if(col, is.null, ~ ""))
}

prepare_adverse_events <- function(.data) {
  .data %>% 
    select_if(function(col) !is.list(col)) %>% 
    mutate_if(is.character, function(col) ifelse(col == "", "", col)) %>% 
    select(id, everything())
}

prepare_patient <- function(.data) {
  x <- .data %>% 
    select(id, patient) %>% 
    mutate_if(is.list, function(col) map_if(col, rlang::is_empty, ~ "")) %>% 
    unnest(patient) %>% 
    mutate_if(is.list, function(col) map_if(col, is.null, ~ "")) %>% 
    unnest(sequence_number_treatment) %>% 
    unnest(sequence_number_outcome)
  
  if ("patient" %in% names(x)) {
    x
  } else {
    mutate(x, patient = "")
  }
}

prepare_remedial_action <- function(.data) {
  .data %>% 
    select(id, remedial_action) %>% 
    unnest(remedial_action)
}

prepare_mdr_text <- function(.data) {
  .data %>% 
    select(id, mdr_text) %>% 
    mutate_if(is.list, function(col) map_if(col, rlang::is_empty, ~ "")) %>% 
    unnest(mdr_text)
}

prepare_type_of_report <- function(.data) {
  .data %>% 
    select(id, type_of_report) %>% 
    unnest(type_of_report)
}

prepare_product_problems <- function(.data) {
  .data %>% 
    select(id, product_problem_flag)
    # select(id, product_problems) %>% 
    # unnest(product_problems)
}

prepare_source_type <- function(.data) {
  .data %>% 
    select(id, source_type) %>% 
    unnest(source_type)
}

prepare_device <- function(.data) {
  x <- .data %>% 
    select(id, device) %>% 
    mutate_if(is.list, function(col) map_if(col, rlang::is_empty, ~ "")) %>% 
    unnest(device) %>% 
    mutate_if(is.list, function(col) map_if(col, is.null, ~ "")) %>% 
    unnest(openfda.fei_number) %>% 
    unnest(openfda.registration_number)
  
  if ("device" %in% names(x)) {
    x
  } else {
    mutate(x, device = "")
  }
}

drop_all_tables <- function(con) {
  if ("adverse_events" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events"))
  if ("adverse_events_patient" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_patient"))
  if ("adverse_events_remedial_action" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_remedial_action"))
  if ("adverse_events_mdr_text" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_mdr_text"))
  if ("adverse_events_type_of_report" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_type_of_report"))
  if ("adverse_events_product_problems" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_product_problems"))
  if ("adverse_events_source_type" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_source_type"))
  if ("adverse_events_device" %in% dbListTables(con)) DBI::dbRemoveTable(con, SQL("device.adverse_events_device"))
}

write_table <- function(con, .data, name) {
  tbl_name <- gsub("device\\.", "", name)
  if (tbl_name %in% dbListTables(con)) {
    dbWriteTable(con, SQL(name), .data, append = TRUE)
  } else {
    dbWriteTable(con, SQL(name), .data, temporary = FALSE)
  }
}

refresh_db <- function(links) {
  start <- Sys.time()
  cli::cli_rule(paste0("openFDA database refresh [", Sys.time(), "]"))
  invisible({future_lapply(links, function(x) {
    tryCatch({
      message("* Running [", x, "]")
      
      # configure
      config <- config_adverse_events(x)
      data <- download_adverse_events(config)
      raw <- prepare_raw(data, config)
      
      # prepare
      adverse_events <- prepare_adverse_events(raw)
      adverse_events.patient <- prepare_patient(raw)
      adverse_events.remedial_action <- prepare_remedial_action(raw)
      adverse_events.mdr_text <- prepare_mdr_text(raw)
      adverse_events.type_of_report <- prepare_type_of_report(raw)
      adverse_events.product_problems <- prepare_product_problems(raw)
      adverse_events.source_type <- prepare_source_type(raw)
      adverse_events.device <- prepare_device(raw)
      
      # write
      write_table(con, adverse_events, "device.adverse_events")
      write_table(con, adverse_events.patient, "device.adverse_events_patient")
      write_table(con, adverse_events.remedial_action, "device.adverse_events_remedial_action")
      write_table(con, adverse_events.mdr_text, "device.adverse_events_mdr_text")
      write_table(con, adverse_events.type_of_report, "device.adverse_events_type_of_report")
      write_table(con, adverse_events.product_problems, "device.adverse_events_product_problems")
      write_table(con, adverse_events.source_type, "device.adverse_events_source_type")
      write_table(con, adverse_events.device, "device.adverse_events_device")
    }, error = function(e) {
      message("! ", e)
    })
  })})
  end <- Sys.time()
  elapsed <- end - start
  message("~ openFDA database refresh completed in [", elapsed, " ", attr(elapsed, "units"), "]")
}
