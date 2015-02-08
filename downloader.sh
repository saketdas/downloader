URL="$1"
filename="$2"
((segSize=2*1024*1024))
((startSegment=1))
((threadCount=10))

if [ "$#" -ne 2 ]
then
  echo "Usage: $0 UrlToDownload OutputFile "
  exit
fi

totalSize=$(curl -sI $URL | awk '/Content-Length/{sub(/\r/,"",$2); print $2}' )
if [ $totalSize -lt 1 ]
then
  echo "Zero content size. Exiting..."
  exit
fi
echo "Using segment size $segSize and saving to file $filename. Total file size is $totalSize."
((totalBlocks=totalSize/segSize))
((lastBlockSize=totalSize%segSize))
if [ $lastBlockSize -gt 0 ]
then
  ((totalBlocks++))
fi

let fileAppender=$(date +%s)
tempCommandFile="./parallelCommands_"$fileAppender
rm -f $tempCommandFile
touch $tempCommandFile

for (( i=$startSegment; i<=$totalBlocks; i++ ))
do
  (( startRange=(i-1)*segSize ))
  (( endRange=startRange+segSize-1 ))
  (( seekPos=i-1 ))
  if [ $i -eq $totalBlocks ]
  then
    ((endRange=totalSize-1))
  fi
  ((currentSegSize=endRange-startRange+1))
  echo "echo \"Downloading $i out of $totalBlocks \" && curl --silent -r $startRange-$endRange '$URL' | dd of=$filename bs=$segSize seek=$seekPos conv=notrunc > /dev/null 2>&1 " >> $tempCommandFile
done
parallel -j $threadCount -k :::: $tempCommandFile
rm -f $tempCommandFile


