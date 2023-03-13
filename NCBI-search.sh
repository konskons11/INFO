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
parse_check=$(awk 'NR%2==0' $input | wc -l)
validity=$(grep ">" $input | wc -l)

if [ $parse_check -eq $validity ] ; then
    seqs=$(awk  'NR%2==0' $input)
else
	parsed=$(seqtk seq -S $input)
    seqs=$(awk 'NR%2==0' <<< "$parsed")
fi
AccIDs=$(grep ">" $input | awk '{print $1}' | sed 's/>//g' )

# Make tabular fasta for later use
tab_fasta=$(paste <(echo "$AccIDs") <(echo "$seqs"))

seq_type_prompt="Please enter type of query sequences:
0=Exit, 1=Protein, 2=Nucleotide"
while true ; do
	echo "$seq_type_prompt"
	read seq_type_input
	if [ "$seq_type_input" -eq "$seq_type_input" 2> /dev/null ] && [ "$seq_type_input" -eq 0 ] ; then
		exit
	elif [ "$seq_type_input" -eq "$seq_type_input" 2> /dev/null ] && [ "$seq_type_input" -ge 1 -a "$seq_type_input" -le 2 ] ; then
		break
	fi
done



### GET INFO FROM NCBI & EXPORT TO .out FILE
echo "Fetching NCBI data, please wait..."

# PROTEIN
if [ "$seq_type_input" -eq 1 ] ; then
	ncbi_data=$(efetch -db protein -id $AccIDs -format gpc) 
	tsv1=$(xtract -input <(echo "$ncbi_data") -insd source organism host country collection_date )
	tsv2=$(xtract -input <(echo "$ncbi_data") -pattern INSDSeq -element INSDSeq_create-date INSDSeq_definition INSDSeq_taxonomy INSDSeq_length )
	# Keep only data from corresponsing accession numbers
	total_tsv=$(paste <(echo "$tsv1") <(echo "$tsv2") <(awk -F'\t' 'NR==FNR { id[$1]=$1 ; seq[$1]=$2 ; next } ($1 in id ){ print seq[$1]}' OFS="\t" <(echo "$tab_fasta") <(echo "$tsv1") ) )
	echo -e "AccessionID\tOrganism\tHost\tCountry\tCollection_date\tSubmission_date\tTitle\tTaxonomy\tSeq_length\tSequence\n$total_tsv" > $output/$filename\_NCBI.out

# NUCLEOTIDE
elif [ "$seq_type_input" -eq 2 ] ; then
	ncbi_data=$(efetch -db nuccore -id $AccIDs -format gbc) 
	tsv1=$(xtract -input <(echo "$ncbi_data") -insd source organism host country collection_date )
	tsv2=$(xtract -input <(echo "$ncbi_data") -pattern INSDSeq -element INSDSeq_create-date INSDSeq_definition INSDSeq_taxonomy INSDSeq_length )
	# Keep only data from corresponsing accession numbers
	total_tsv=$(paste <(echo "$tsv1") <(echo "$tsv2") <(awk -F'\t' 'NR==FNR { id[$1]=$1 ; seq[$1]=$2 ; next } ($1 in id ){ print seq[$1]}' OFS="\t" <(echo "$tab_fasta") <(echo "$tsv1") ) )
	echo -e "AccessionID\tOrganism\tHost\tCountry\tCollection_date\tSubmission_date\tTitle\tTaxonomy\tSeq_length\tSequence\n$total_tsv" > $output/$filename\_NCBI.out

fi



### SELECT NCBI DATA TO EXPORT AS FASTA
data_export_prompt="Please select NCBI data to export:
0=Exit, 1=Host-Country, 2=Host-Country-Dates"
while true ; do
	echo "$data_export_prompt"
	read data_export_prompt
	if [ "$data_export_prompt" -eq "$data_export_prompt" 2> /dev/null ] && [ "$data_export_prompt" -eq 0 ] ; then
		exit
	elif [ "$data_export_prompt" -eq "$data_export_prompt" 2> /dev/null ] && [ "$data_export_prompt" -eq 1 ] ; then
		data_to_export='">"$2"_"$1"|"$3"_"$4"\n"$10'
		break
	elif [ "$data_export_prompt" -eq "$data_export_prompt" 2> /dev/null ] && [ "$data_export_prompt" -eq 2 ] ; then
		data_to_export='">"$2"_"$1"|"$3"_"$4"_"$5"_"$6"\n"$10'
		break
	fi
done


final_fasta=$(awk -F'\t' 'NR>1 {print '$data_to_export'}' $output/$filename\_NCBI.out | sed 's/\://g' | sed 's/\;//g' | sed 's/\,//g' | sed 's/\[//g' | sed 's/\]//g' | sed 's/ /_/g' )
echo "$final_fasta" > $output/$filename\_NCBI.fasta

echo "PROCESS COMPLETE!!!"

