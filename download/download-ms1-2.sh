#ms1 data download
mkdir -p ms1-2

ms1names=$(cut -d, -f1 params/sampleInfo-2.csv | tail -n +2)

#Loop through sample info file
for i in $ms1names
do 
echo "Downloading ms1 file $i"
curl -L https://www.ebi.ac.uk/metabolights/MTBLS233/files/${i} -o ms1-2/$i
done