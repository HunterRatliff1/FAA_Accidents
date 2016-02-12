FAA <- read.csv(
  "http://www.asias.faa.gov/pls/apex/f?p=100:93::FLOW_EXCEL_OUTPUT_R2161113456916636_en", na.strings = "") %>%
  
  # Rename the columns
  rename(date=EVENT_LCL_DATE,           time=EVENT_LCL_TIME,         city=LOC_CITY_NAME, 
         state=LOC_STATE_NAME,          Event.Type_desc=EVENT_TYPE_DESC,
         Reg.num=REGIST_NBR,            Flight.num=FLT_NBR,          Craft.Opperator=ACFT_OPRTR,
         Craft.Make=ACFT_MAKE_NAME,     Craft.Model=ACFT_MODEL_NAME, Craft.Damage=ACFT_DMG_DESC,
         Flight.Activitiy=FLT_ACTIVITY, Flight.Phase=FLT_PHASE,      Fatal=FATAL_FLAG,
         Injury.Max.Level=MAX_INJ_LVL,  Description=RMK_TEXT) %>%
  
  # Drop these columns
  select(-UPDATED, -ENTRY_DATE, -LOC_CNTRY_NAME, -FAR_PART, -FSDO_DESC, -ACFT_MISSING_FLAG)

# Create a date/time column 
require(lubridate)
FAA$date <- dmy(FAA$date) + hms(FAA$time)
FAA$time <- NULL

# Adjust capitlilzation to make pretty
require(stringi)
FAA$city <- stri_trans_totitle(FAA$city)
FAA$city <- as.factor(FAA$city)
FAA$Description <- stri_trans_totitle(FAA$Description)
FAA$Craft.Opperator  <- stri_trans_totitle(FAA$Craft.Opperator)
FAA$Craft.Opperator <- as.factor(FAA$Craft.Opperator)

# Geocode the incidents 
require(ggmap)
geocodes <- geocode(paste0(FAA$city, ", ",FAA$state))

# Bind to original data.frame
FAA <- bind_cols(FAA, geocodes)

# Melt data frame using reshape2 package
FAA <- melt(data = FAA, measure.vars = c("FLT_CRW_INJ_NONE", "FLT_CRW_INJ_MINOR", "FLT_CRW_INJ_SERIOUS", "FLT_CRW_INJ_FATAL", "FLT_CRW_INJ_UNK","CBN_CRW_INJ_NONE", "CBN_CRW_INJ_MINOR", "CBN_CRW_INJ_SERIOUS", "CBN_CRW_INJ_FATAL", "CBN_CRW_INJ_UNK","PAX_INJ_NONE", "PAX_INJ_MINOR", "PAX_INJ_SERIOUS", "PAX_INJ_FATAL", "PAX_INJ_UNK","GRND_INJ_NONE", "GRND_INJ_MINOR", "GRND_INJ_SERIOUS", "GRND_INJ_FATAL", "GRND_INJ_UNK"), na.rm = T, variable.name = "Injury.Type", value.name = "Injury.Count")

# Make a column for if the crash was fatal
FAA$Fatal <- ifelse(is.na(FAA$Fatal), "No", "Yes")

# Pretty the Injury Types
FAA$Injury.Type <- gsub("PAX_INJ_", "Passanger ", FAA$Injury.Type)
FAA$Injury.Type <- gsub("CBN_CRW_INJ_", "Cabin Crew ", FAA$Injury.Type)
FAA$Injury.Type <- gsub("FLT_CRW_INJ_", "Flight Crew ", FAA$Injury.Type)

# Make title case
FAA$Flight.Phase <- stri_trans_totitle(FAA$Flight.Phase)

# Write out as CSV & RDS
FAA %>% write.csv("FAA-data.csv")
FAA %>% saveRDS("FAA-data.RDS")