### script for excel template generation

# load data ---------------------------------------------------------------
library(readxl)
schema <- readxl::read_xlsx("experimental_context_description.xlsx")

# excel generation --------------------------------------------------------
library(openxlsx)

#filtre<-c("expe_name","expe_start_date","expe_end_date","expe_obj","expe_desc","expe_contact","expe_email","expe_proj")
#entity="experimentation"
library(dplyr)


#' function to add a new sheet with cell validation
#'
#' @param entity the entity name from vitisdatacrop schema
#' @param numlist the xlsx sheet's list to be incremented
#' @param wb template excel workbook
#'
#' @return
#' @export
#'
#' @examples
add_sheet2template <- function(entity,wb)
{
  metadata <- schema[grep(entity,strsplit(schema$name, split=",", fixed = TRUE)),] ## to filter metadata for the entity
  metadata <- metadata %>%
    #filter(name == entity) %>% # filter metadata you want
    filter (core=="true") %>% # filter only "core" metadata
    mutate(valeur="") %>% # add an empty col for future values
    arrange(order) ### to arrange by col order

  #metadata <- left_join(data.frame(name=filtre),metadata,by="name") # to reorder by vector filtre
  # selection of cols to export to excel
  selection=c("label_fr","valeur") ## list of cols you want
  metadata_selected <- metadata %>% select(all_of(selection))
  metadata_selected_t <- as.data.frame(t(metadata_selected[,-1]))
  ### add an * if required
  label <- metadata_selected$label_fr
  metadata$required[is.na(metadata$required)]<-0 ##
  label[metadata$required==1]<-paste0(label[metadata$required==1],"*")
  colnames(metadata_selected_t) <- label

    ### to check if a sheets "listes" exists and to extract the number of cols of this sheet
  if ("listes" %in% wb$sheet_names)
  {
    numlist <- ncol(openxlsx::readWorkbook(wb,sheet="listes"))
    if(is.null(numlist)) {numlist <- 0}
  } else {
    addWorksheet(wb, "listes") # Add worksheet "listes" to the workbook
    numlist <- 0  # num of listes
  }

  openxlsx::addWorksheet(wb,sheet=entity)
  openxlsx::writeDataTable(wb,sheet=entity,x=metadata_selected_t) # # copy metadata_selected to the sheet
  openxlsx::setColWidths(wb, sheet = entity, cols = c(1:ncol(metadata_selected_t)), widths = "auto") ## auto adjust of col width
  #s1 <- createStyle(fontSize = 12, fontColour = "red", textDecoration = c("BOLD")) ## create style for the comment
  #s_required <- createStyle(fontColour = "red",textDecoration = c("BOLD")) ## create style for required field
  champs<-metadata$property

  #ncolval <- which(selection=="valeur") ## num of values col
  for (i in 1:length(champs))
  {
    ## add comment for description
    c1 <- openxlsx::createComment(metadata$description[i],visible=F) ## create comment
    openxlsx::writeComment(wb,sheet=entity,col=i,row=1,comment=c1) ## write the comment in cell "name"

    ## add comment for example (disabled : better to have a example file)
    # c_ex <- openxlsx::createComment(metadata$example[i],visible=F) ## create comment
    # openxlsx::writeComment(wb,sheet=entity,col=ncolval,row=i+1,comment=c_ex) ## write the comment in cell "name"


    ## add named region to the cols (arbitrary 100 rows)
    createNamedRegion(wb,sheet=entity,cols=i,rows=2:100,
                      name = paste(entity,metadata$property[i],sep=".")) #

    ### add list
    enum_i <- metadata$enumList[metadata$property==champs[i]]
    if (!is.na(enum_i))
    {
      numlist <- numlist+1 # increment num of listes
      # Create drop-down values dataframe
      list_df = data.frame(strsplit(enum_i,split=","))
      colnames(list_df)<-champs[i]
      # Add drop-down values dataframe to the sheet "Drop-down values"
      writeData(wb, sheet = "listes", x = list_df, startCol = numlist)
      # add validation to sheet (arbitrary 100 rows)
      openxlsx::dataValidation(wb,sheet=entity,col=i,rows=2:100,type="list",
                               value=paste0("'listes'!$",LETTERS[numlist],"$",2,":$",LETTERS[numlist],"$",nrow(list_df)+1))
    } else {}

    ## add min and max values
    range<-c(metadata$minimum[metadata$property==champs[i]],metadata$maximum[metadata$property==champs[i]])
      if (length(na.omit(range))==2)
    {
      openxlsx::dataValidation(wb,sheet=entity,col=i,rows=2:100,type="decimal",
                             operator = "between", value = range)
      } else {
        if (!is.na(range[1]))
        {
          openxlsx::dataValidation(wb,sheet=entity,col=i,rows=2:100,type="decimal",
                                   operator = "greaterThan", value = range[1])
        }
        if (!is.na(range[2]))
        {
          openxlsx::dataValidation(wb,sheet=entity,col=i,rows=2:100,type="decimal",
                                   operator = "lessThan", value = range[1])
        }
        } # end of else
  } # end of function
  sheetVisibility(wb)[wb$sheet_names == "listes"] <- "veryHidden" ## hide sheet listes
  return(wb)
}

### create template

# liste sheet ------------------------------------------------------------
## add a sheet for each entity
entities <- unique(unlist(strsplit(schema$name[schema$core=="true"], split=",", fixed = TRUE)))

#schema %>% filter (core=="true") %>%  select(name) %>% unique
#entities <- unique(schema$name)
entities <- na.omit(entities)

ordered_entity <- c("person","project","experimentation","design","moda","treatment_xp","data_dictionary","field","estate","soil","itk","annotation")


wb <- openxlsx::createWorkbook()  ## create a new workbook
for (i in 1:length(ordered_entity))
{
  wb <- add_sheet2template(entity=ordered_entity[i], wb = wb)
}

# wb <- add_sheet2template(entity="itk", wb = wb)

### adding soil texture triangle
insertImage(wb, "soil", "TriangleTextureGEPPA17cl.png", startRow = 5, startCol = 3,
            width = 13, height = 12, units = "cm")

### addig a help page
openxlsx::addWorksheet(wb,sheetName = "HELP")
writeDataTable(wb,sheet="HELP", x= schema %>%
                 filter (core=="true") %>%
                 select(name,label_fr,description,example,help),
               bandedRows = T)


# saving wb ---------------------------------------------------------------
options(openxlsx.dateFormat = "yyyy-mm-dd")
addCreator(wb, Creator="IFV,Standard v1")
saveWorkbook(wb, "template.xlsx", overwrite = TRUE)


