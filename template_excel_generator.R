### script for excel template generation

# load data ---------------------------------------------------------------
library(readxl)
schema <- readxl::read_xlsx("experimental_context_description.xlsx")

# excel generation --------------------------------------------------------
library(openxlsx)

#filtre<-c("expe_name","expe_start_date","expe_end_date","expe_obj","expe_desc","expe_contact","expe_email","expe_proj")
#entity="experimentation"
library(dplyr)
# function to add a new sheet with cell validation 
add_sheet2template <- function(entity,numlist)
{
  metadata <- schema %>%
    filter(name == entity) %>% # filter metadata you want
    mutate(valeur="")  # add an empty col for future values
  
  #metadata <- left_join(data.frame(name=filtre),metadata,by="name") # to reorder by vector filtre
  # selection of cols to export to excel
  selection=c("label_fr","valeur","description") ## list of cols you want
  
  openxlsx::addWorksheet(wb,sheet=entity)
  openxlsx::writeDataTable(wb,sheet=entity,x=metadata %>% select(all_of(selection))) # # copy only metadata you want
  champs<-metadata$property
  
  ncolval <- which(selection=="valeur") ## num of values col
  for (i in 1:length(champs))
  {
    enum_i <- metadata$enumList[metadata$property==champs[i]]
    if (!is.na(enum_i))
    {
      numlist <- numlist+1 # increment num of listes
      # Create drop-down values dataframe
      list_df = data.frame(strsplit(enum_i,split=","))
      colnames(list_df)<-champs[i]
      # Add drop-down values dataframe to the sheet "Drop-down values"
      writeData(wb, sheet = "listes", x = list_df, startCol = numlist)
      # add validation to sheet
      openxlsx::dataValidation(wb,sheet=entity,col=ncolval,rows=i+1,type="list",
                               value=paste0("'listes'!$",LETTERS[numlist],"$",2,":$",LETTERS[numlist],"$",nrow(list_df)+1))
    } else {}
    range<-c(metadata$minimum[metadata$property==champs[i]],metadata$maximum[metadata$property==champs[i]])
      if (length(na.omit(range))==2)
    {
      openxlsx::dataValidation(wb,sheet=entity,col=ncolval,rows=i+1,type="decimal",
                             operator = "between", value = range)
      } else {
        if (!is.na(range[1]))
        {
          openxlsx::dataValidation(wb,sheet=entity,col=ncolval,rows=i+1,type="decimal",
                                   operator = "greaterThan", value = range[1])
        }
        if (!is.na(range[2]))
        {
          openxlsx::dataValidation(wb,sheet=entity,col=ncolval,rows=i+1,type="decimal",
                                   operator = "lessThan", value = range[1])
        }
        } # end of else
  } # end of function
  return(numlist)
}

### create template
wb <- openxlsx::createWorkbook()  ## create a new workbook

# liste sheet ------------------------------------------------------------
addWorksheet(wb, "listes") # Add worksheet "listes" to the workbook
numlist <- 0  # num of listes

## add a sheet for each entity
entities <- unique(schema$name)
entities <- na.omit(entities)

for (i in 1:length(entities))
{
  newNL <- add_sheet2template(entity=entities[i],numlist = numlist)
  numlist <- newNL
}

# saving wb ---------------------------------------------------------------
saveWorkbook(wb, "template.xlsx", overwrite = TRUE)

