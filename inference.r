
library(ggplot2)
library(rjags)
source('load_drafts.r')

QBs <- subset(Drafts, Position == 'QB')

## QBs must be drafted in at least 20% of drafts
## Removes clowns like Jim Sorgi showing up
Drafted.QBs <- subset(ddply(QBs, .(Player), summarise,
                            drafts = length(Order)),
                      drafts > length(unique(QBs$Draft))*0.20)
QBs <- join(QBs, Drafted.QBs, type = 'inner')

## Generate pairwise comparisons.  We only need one direction here.
## They're linked to a user-draft identity
Pairwise <- ddply(QBs, .(Draft), function(x) {
  # generate all pairwise comparisons
  x2 <- merge(x, x, by = integer(0), all = TRUE, suffixes= c('', '2'))
  # get the winner > loser rows made by humans
  subset(x2, Human == 1 & Order < Order2, c('Drafter', 'Player', 'Player2'))
})

Unique.QBs <- unique(c(as.character(Pairwise$Player),
                       as.character(Pairwise$Player2)))

## Convert these to new factors with the same levels
Pairwise$Player <- factor(as.character(Pairwise$Player),
                          levels = Unique.QBs)
Pairwise$Player2 <- factor(as.character(Pairwise$Player2),
                          levels = Unique.QBs)

## Drafter ID factor
Pairwise$DrafterId <- as.factor(with(Pairwise,
    paste(as.character(Draft), '-', as.character(Drafter), sep='')))

model.data <- list(
    'N' = nrow(Pairwise),
    'nplayers' = length(Unique.QBs),
    'ndrafters' = length(unique(Pairwise$DrafterId)),
    'drafterids' = as.integer(Pairwise$DrafterId),
    'winnerids' = as.integer(Pairwise$Player),
    'loserids' = as.integer(Pairwise$Player2),
    'wins' = rep(1, nrow(Pairwise))
    )
                   
m <- jags.model('ranking_personal.jags',
                data = model.data,
                n.chains = 1,
                n.adapt = 1000)

##update(m, 10000)
 
samples <- jags.samples(m, c('player_quality', 'player_variance'), 1000)

output.df <- data.frame(qb=Unique.QBs, quality=rowMeans(samples$player_quality), variance=rowMeans(samples$player_variance))[order(rowMeans(samples$player_quality), decreasing=T),]

ggplot(output.df, aes(x = variance, y = quality)) + geom_point() + geom_text(aes(label = qb)) + xlim(-2, 22)
