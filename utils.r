library(XML) ## parsing the html tables
library(stringr) ## for str_trim

## Thanks to Drew Conway for the original code I've adapted here
## https://github.com/drewconway/ZIA/blob/master/R/SampleSpace/draft_position.R
## http://drewconway.com

get.df.file<-function(draft.id) {
  ## Retruns draft data as properly formatted data frame
  cat('parsing draft id:', draft.id, '\n')
  
  f <- file(paste('drafts', draft.id, sep='/'))
  html <- scan(f, what=character(0), sep="\n", quiet=TRUE)
  close(f)

  ## this is a crappy heuristic, but it works for non-draft pages
  if (length(html) != 181){
    return(data.frame())
  }

  ## fancy code to 
  html.clean <- gsub("<br/>"," ", html)
  
  doc <- htmlParse(html.clean, asText=TRUE)
  tableNodes = getNodeSet(doc, "//table")
  draft.table <- readHTMLTable(tableNodes[[2]], stringsAsFactors=F)
  draft.table <- draft.table[,2:ncol(draft.table)]

  n.drafters <- ncol(draft.table)
  user.names <- colnames(draft.table)
  
  n.rounds <- nrow(draft.table)

  draft.order <- cbind(kronecker(1:n.rounds, rep(1, n.drafters)),
                       c(1:n.drafters, n.drafters:1))
  drafters <- c(user.names, user.names[n.drafters:1])
  humans <- as.integer(colnames(draft.table) != as.character(1:n.drafters))
  humans <- c(humans, humans[n.drafters:1])
  
  picks <- draft.table[draft.order]
  ## Create seperate columsn for player name, position and team
  picks <- strsplit(picks, "[\\(\\)]")
  picks <- do.call(rbind, picks)
  player.pos <- picks[,1]  # Players
  team <- picks[,2]    # Team
  ## Create vector for player position
  pos <- str_trim(sapply(player.pos,function(x) substring(x,first=nchar(x)-3, last=nchar(x)-1)))
  ## Strip keep just player name
  player <- str_trim(sapply(player.pos,function(x)substring(x,first=1,last=nchar(x)-4)))
  
  order <- 1:length(player)
  df <- cbind(draft.id,player,pos,team,order,drafters,humans)
  row.names(df) <- order
  colnames(df) <- c("Draft", "Player","Position","Team","Order","Drafter", "Human")
  df <- as.data.frame(df)
  df$Order <- as.numeric(as.character(df$Order))
  df
}
