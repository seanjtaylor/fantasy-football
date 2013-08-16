# Inferring Fantasy Player Quality From Draft Decisions

## Introduction

During every fantasy football draft, players make many choices which reveal their opinions about which players are going to produce points during the season.  They each have different information, resources, and mental (or even formal!) models which drive their valuations for players.

So instead of forming my own projections about which players are the best to draft, I decided to steal the information revealed by hundreds of players' draft decisions as they completed [mock drafts](http://fantasyfootballcalculator.com/completed_drafts.php).

Full disclosure, I totally [stole this idea](http://www.r-bloggers.com/leveraging-the-wisdom-of-crowds-for-fantasy-football/) from [Drew Conway](http://drewconway.com), who despite being a Giants fan is actually a really smart guy.  But I'm not a total thief, I'm going to add my own Bayesian flare here (the frequentists have flare that they make their followers wear, too).

## Why Fantasy Football?

I like learning new statistics methods and I care about football.  When people ask me how to become a data scientist, I frequently say "find a problem you care about and try to solve it the best you that you can."  Starting with problems that motivate you is the best way to learn new tools and techniques -- and they can frequently be applied elsewhere.

## What Drafts Reveal

During a typical "snake" draft, each of 8-12 players are assigned an order to draft in and the order is reversed for each round.  Usually drafters will choose 15 NFL players in this sequence.  While there is some strategy to when certain positions are chosen based on their relative value, we can infer a set of pairwise orderings form each pick.

Say you pick Aaron Rodgers while Drew Brees is still available.  We can infer that you valued Rodgers more than Brees (as well as many other quarterbacks available at that point).  Thus each pick induces many pairwise comparisons for an individual.  We can use this information to infer their valuations for the players.

Each draft proceeds differently and in many cases people might pick Brees over Rodgers.  They must be doing this because they have different valuations for the players and therefore there isn't a consensus about which of the two is the better pick.  In general we can think of each person in the population having a potentially different valuation for every player.  Like so:

<img src="https://raw.github.com/seanjtaylor/fantasy-football/master/figures/qb.examples.png">

## Modelling Valuations

My favorite way to model situations is to write down a process that could have generated the draft data.  Here we can assume everyone drafting must have a valuation for each player so they can make all these pairwise comparisons.  So index NFL players by $i$ and drafters by $j$.  Then we can say $q_{ij}$ is $j$'s value for player $i$.

Now these signals are probably coming from somewhere.  Each drafter reads news, fantasy experts, and statistics to inform his decision.  Let's assume that they are draw from a per-player distribution:

\[ q_{ij} \sim Normal(\mu_i, \sigma_i) \]

So the signals about each player follow a normal distribution with different means -- if they are on average considered to be better or worse -- and different standard deviations, representing disagreement about the valuation.

In the Bayesian framework, we'll need priors on $\mu_i$ and $\sigma_i$.  I'll use a fairly non-informative prior on these to let the data describe these parameters.

Now we need a function that maps $q_{ij}$ to our data.  If we see drafter $j$ pick player $1$ while $2,3, \ldots$ were available, then we can say it is likely that $q_{1j} > q_{2j}$, $q_{1j} > q_{3j}$, etc.  We can use a simple logit model for this:

\[ P(q_{1j} > q_{2j}) = frac{1}{1 + e^{q_{2j} - q_{1j}}} \]

This is just one model of the process, but I think it has some nice properties and has the advantage of being fairly straightforward to code in JAGS:

    model {
      for (i in 1:nplayers) {
        player_quality[i] ~ dnorm(0, 0.1)
        player_variance[i] ~ dunif(1, 20)
        for (j in 1:ndrafters) {
          signal[i,j] ~ dnorm(player_quality[i], 1/player_variance[i])
        }
      }
      for (k in 1:N) {
        picks[k] ~ dbern(p[k])
        logit(p[k]) <- signal[winnerids[k], drafterids[k]] - signal[loserids[k], drafterids[k]]
      }
    }

## Data Scraping / Munging

I've scraped 930 mock drafts from the [Fantasy Football Calculator](http://fantasyfootballcalculator.com/).  Scraping the data is done by running `source fetch_drafts.sh`.  The `load_drafts.r` file shows how to load these HTML files into an R dataframe

For quarterbacks alone, this data set generates 187,000 pairwise comparisons made by humans (some of the drafting are done by their computer system).  These pairwise comparisons combined with a unique identifier for each drafter who makes them looks like:

<table>
    <tr>
        <th>Drafter Id</th>
        <th>Picked Player</th>
        <th>Nonpicked Player</th>
    </tr>
    <tr>
        <td>1</td>
        <td>Drew Brees</td>
        <td>Aaron Rodgers</td>
    </tr>
    <tr>
        <td>1</td>
        <td>Drew Brees</td>
        <td>Peyton Manning</td>
    </tr>
    <tr>
        <td>1</td>
        <td>Drew Brees</td>
        <td>Eli Manning</td>
    </tr>
</table>

## Estimation

I estimate the generative model described above using JAGS.  You can see the code to do this in `inference.r`.

Here's what the mean/variance parameters for QBs looks like so far:

<img src="https://raw.github.com/seanjtaylor/fantasy-football/master/figures/qb.mean.variance.png">

