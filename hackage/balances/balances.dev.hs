#!/usr/bin/env stack
-- stack script --resolver lts-20 --package "random text Decimal hledger-lib" --verbosity info
{- 
balances.dev.hs, readable/dev version of balances.hs.
Code is fairly terse for easy minification.
Legend:
bs   balance report items
a    account name
b    account balance, possibly multicurrency
g    guess
d    absolute integer difference of guess
e    absolute percentage error of guess
f    e with fewer decimal places
s    score from 0 to 100
p    putStrLn
gu   guess repl/game loop
er   calculate error in one currency. Returns rounded difference and percentage difference.
av   calculate average

Reference
README
http://hackage.haskell.org/package/hledger-lib/docs/Hledger.html
http://hledger.org/scripting.html#hledger-lib-scripts
-}

{-# LANGUAGE PackageImports #-}
--     package       module         symbols imported
import "random"      System.Random  (randomRIO)
import "text"        Data.Text      (pack,unpack)
import "Decimal"     Data.Decimal   (roundTo)
import "hledger-lib" Hledger
  (defaultJournal,defreportspec,_rsQuery,Query(..),AccountType(..),balanceReport,
   mixedAmountStripPrices,aquantity,amounts,showMixedAmountOneLine)

-- Read the default hledger journal ($LEDGER_FILE or ~/.hledger.journal)
-- and calculate the balances of asset and liability accounts.
main = defaultJournal >>= gu . fst . balanceReport defreportspec{_rsQuery=
  Type[Asset,Liability]}
-- And[Type[Asset,Liability],Sym$toRegex'$T.pack"^.$",Acct$toRegex'$T.pack"paypal"] }
-- Acct$toRegex'$T.pack"Vanguard:Cash" }

-- Given some account balances: loop showing a random account name,
-- prompting for and scoring a guess of its balance, until a successful guess.
-- A guess is a positive integer, attempting to match the integral part
-- of the balance's most numerous commodity. Score ranges from 0 to 100.
-- gu :: [BalanceReportItem] -> IO ()
gu [] = putStrLn "no balances found"
gu bs = do
  i<-randomRIO(0,length bs-1)
  let (a,_,_,b0) = bs !! i
  putStr $ "\n"++unpack a++" balance ? "
  g <- getLine
  let
    b = mixedAmountStripPrices b0
    q = maximum $ 0 : map (abs.aquantity) (amounts b)
    (d,p) = er (read g) q
    p' = roundTo 1 p
    s = 100-min 100 p'
  if d/=0
  then putStrLn("Off by ~"++show d++", score: "++show s) >> gu bs
  else putStrLn$"Correct! The balance is "++showMixedAmountOneLine b++"."

-- Given a guess and an actual balance (both single-currency),
-- calculate their rounded difference and percentage difference.
-- er :: (RealFrac a, RealFrac b) => a -> b -> (Int, b)
er g b = let d=abs$round g-round b in (d,fromIntegral d*100/b+0.001)

-- Calculate an average, safely.
-- av :: (Fractional a, Foldable t) => t a -> a
av as = sum as / if null as then 1 else fromIntegral (length as)
