key=`cat key`
md5Array=`cat md5list`

optRaw () {
  echo $1 | jq -r ".$2"
}

opt () {
  echo $1 | jq ".$2"
}

callApi(){
  fileName=$1
  result=`curl https://api.tinify.com/shrink --user api:$key --data-binary @$fileName`
  wait
  input=`opt "$result" input`
  output=`opt "$result" output`
  dlCompressedPng "$output" $fileName
}

dlCompressedPng(){
  output=$1
  fileName=$2
  dlUrl=`optRaw "$output" url`
  size=`optRaw "$output" size`
  echo 'dl start'
  curl $dlUrl --user api:$key --output $fileName
  wait
  echo 'dl end'
  succ=checkDlSucc $fileName $size
  if [ $succ ]; then
    newMd5Val=`md5sum ${fileName} | awk '{ print $1 }'`
    echo $newMd5Val >> 'md5list'
  fi
}

checkDlSucc(){
  fileName=$1
  size=$2
  destSize=`ls -l $fileName | awk '{print $5}'`
  if [ $size=$destSize ]; then
    echo true
  else
    echo false
  fi
}

walk(){
  srcDir=$1
  destDir=$2
  for fileName in `find $srcDir -name \*.png -print`; do
    currMd5Val=`md5sum ${fileName} | awk '{ print $1 }'`
    if [ !$(find_in_array $currMd5Val $md5Array) ]; then
      prefix=$(basename "$fileName" ".png")
      backup $fileName "$destDir/$prefix.$currMd5Val.png"
      callApi $fileName
      echo '------------'
    fi
  done
}

backup() {
  echo 'copy from '$1' to '$2
  cp $1 $2
}

find_in_array() {
  local word=$1
  local array=$2
  shift
  for element in $array; do
    [[ $element == $word ]] && return 0;
  done
}

walk $1 $2