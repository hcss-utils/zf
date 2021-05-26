# install.packages(c("magrittr", "DBI", "RSQLite", "quanteda", "readtext"))
library(magrittr)
library(DBI)
library(RSQLite)
library(quanteda)
library(readtext)

ZOTERO = "C:/Users/hryho/Zotero"
DB_PATH = paste0(ZOTERO, "/zotero.sqlite")
OUTPUT_CSV = "data/output.csv"

# connect to Zotero's SQLite database
con = dbConnect(
  drv = RSQLite::SQLite(),
  dbname = DB_PATH
)

# get names of all tables in the database
alltables = dbListTables(con)

# bring the items and itemNotes tables into R
table.items <- dbGetQuery(con, 'select * from items')
table.itemNotes <- dbGetQuery(con, 'select * from itemNotes')

# bring in Zotero fulltext cache plaintext
textDF <- readtext(
  paste0(ZOTERO, "/storage", "/*/.zotero-ft-cache"),
  docvarsfrom = "filepaths"
)

# isolate "key" (8-character alphanumeric directory in storage/) in docvar1 associated with plaintext
textDF$docvar1 <- gsub(pattern = "^.*storage\\/", replacement = "", x = textDF$docvar1)
textDF$docvar1 <- gsub(pattern = "\\/.*", replacement = "", x = textDF$docvar1)

# bring in itemID (and some other metadata) and that's all
textDF <- textDF %>%
  dplyr::rename(key = docvar1) %>%
  dplyr::left_join(table.items) %>%
  dplyr::filter(!is.na(itemID), !itemID %in% table.itemNotes$itemID) %>%
  write.csv(.,file = OUTPUT_CSV)
