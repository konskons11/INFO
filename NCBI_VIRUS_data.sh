#!/bin/bash

# DESCRIPTION:
# Get HOST and COUNTRY data of FASTA AccIDs from NCBI e-direct tool

# ARGUMENTS
# 1) INPUT = directory of FASTA format .fasta or .fa or .txt file
# 2) OUTPUT = directory of OUTPUT FOLDER

input="$1"
output="$2"

extension="${input##*.}"
if [[ $extension == "fasta" ]] ; then
        filename=$(basename $input .fasta)
elif [[ $extension == "fa" ]] ; then
        filename=$(basename $input .fa)
elif [[ $extension == "txt" ]] ; then
        filename=$(basename $input .txt)
else
        exit
fi


### FASTA DATA EXTRACTION
seqs=""
seqIDs=""
parse_check=$(awk 'NR%2!=0' "$input")
parse_check=$(wc -l <<< "$parse_check")
validity=$(grep ">" <<< "$parse_check" | wc -l)

if [ $parse_check -eq $validity ] ; then
        seqs=$(awk  'NR%2==0' "$input")
else
	parsed=$(awk '/^>/{print (NR==1)?$0:"\n"$0;next}{printf "%s", $0}END{print ""}' "$input" )
        seqs=$(awk 'NR%2==0'  <<< "$parsed")
fi
seqIDs=$(grep ">" "$input" )

title=$(  grep -o '\[.*]' <<< "$seqIDs" | sed 's/\[//g' | sed 's/\]//g' | sed 's/ /_/g' | sed 's/-/_/g' )
AccIDs=$(awk '{print $1}' <<< "$seqIDs" | sed 's/\>//g')



### COLUMNATE FASTA DATA, FILTER-OUT DUPLICATES & EXPORT NEW FASTA 
tsv=$(paste  <(echo "$title") <(echo "$AccIDs") <(echo "$seqs") )

unique=$(cat -n <<< "$tsv" | sort -u -k2,2 | sort -nk1 | cut -f2- )

uniq_title=$(awk '{print ">"$1}' <<< "$unique" )
uniq_AccIDs=$(awk '{print $2}' <<< "$unique" )
uniq_seqs=$(awk '{print $3}' <<< "$unique" )



### GET HOST & COUNTRY DETAILS FROM NCBI & EXPORT TO .out FILE
echo "Fetching NCBI data, please wait..."

id=$(tr '\n' ',' <<< "$uniq_AccIDs" )
ncbi_data=$(efetch -db protein -id $id -format gpc | xtract -insd source host country )

echo -e "AccessionID\tHost\tCountry\n$ncbi_data" > $output/$filename\_NCBI.out


### ADD HOST & COUNTRY DATA TO PREVIOUS NEW_FASTA & EXPORT as .fasta
ncbi_data=$(awk 'NR>1 {for (i=2 ; i<=NF ; i++) printf "%s_", $i; print ""}' $output/$filename\_NCBI.out | sed 's/.$//g' | sed 's/^-_//g' | sed 's/\._/_/g' | sed 's/:_/_/g' | sed 's/,_/,/g')

final_fasta=$(paste -d'_|\n' <(echo "$uniq_title") <(echo "$uniq_AccIDs") <(echo "$ncbi_data") <(echo "$uniq_seqs"))
echo "$final_fasta" > $output/$filename.fasta

echo "PROCESS COMPLETE!!!"

