sed -i -e 's/\bae\b/aE/g
s/\bao\b/oc5/g
s/\baw\b/aUU/g
s/\bax\b/etu/g
s/\bay\b/aih/g
s/\bch\b/tS/g
s/\bdh\b/D/g
s/\bea\b/eetu/g
s/\beh\b/eo5/g
s/\bel\b/l+/g
s/\bem\b/m+/g
s/\ben\b/n+/g
s/\bey\b/eih/g
s/\bhh\b/h/g
s/\bia\b/ihetu/g
s/\biy\b/i/g
s/\bjh\b/dZ/g
s/\bng\b/N/g
s/\boh\b/ao/g
s/\bow\b/oUU/g
s/\boy\b/oc5ih/g
s/\br\b/rr/g
s/\bsh\b/S/g
s/\bth\b/T/g
s/\bua\b/UUetu/g
s/\buh\b/UU/g
s/\buw\b/u/g
s/\bw\b/W/g
s/\by\b/j/g
s/\bzh\b/Z/g' lexicon.txt
sed -i -e 's/\(^\S*\)/\L\1/' lexicon.txt
