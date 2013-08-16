
Peyton <- function(x) {
  dnorm(x, 23.19, sqrt(1.873))
}

Kaep <- function(x) {
  dnorm(x, 9.4182732, sqrt(17.857077))
}

Brees <- function(x) {
  dnorm(x, 28.34, sqrt(7.488727))
}

res <- 500
quality <- seq(-5, 40, length.out = res)
df <- data.frame('Player' = c(rep('Peyton Manning', res),
                   rep('Colin Kaepernick', res),
                   rep('Drew Brees', res)),
                 'Quality' = quality,
                 'Prob' = c(Peyton(quality), Kaep(quality), Brees(quality)))
                 
ggplot(df, aes(x = Quality, y = Prob, colour = Player)) + geom_line() + theme_bw()

ggsave('figures/qb.examples.png')
