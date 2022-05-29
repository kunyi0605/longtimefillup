#!/bin/bash

find ./ -type f -exec chmod 777 {} \;
echo "Set device to test: targetDevice"
#read target
echo "Set loop times: loopCnt"
#read loopTime

target=$1
loopTime=$2

declare -i num
declare -i sec
declare -i min
declare -i hour
declare -i day

libCheck()
{
filepath="/usr/lib/libaio.so.1"

if [ -e $filepath ];then

     echo 

else

     cp libaio.so.1 /usr/lib/
     echo 
fi
}

displayTime()
{
sec=$num%60
min=($num/60)%60
hour=($num/3600)%24
day=$num/3600/24
}

mainTest()
{
echo "Making file system ..." | tee -a $output   
echo | tee -a $output 

mke2fs -F /dev/$target 

mount /dev/$target /mnt

fn=$(df -k | grep -i $target | awk {'print $2'}) 

Capacity=${fn}

declare -i size=$Capacity

if [ "$Capacity" -gt "313524224" ];then   # 299GB=299*1024*1024K 
  size=$Capacity*1000/1024*1000*1000*33/100/1024/1024
elif [ "$Capacity" -gt "103809024" ];then # 99GB=99*1024*1024K
  size=96679688                           # 100GB=99*1000/1024*1000*1000+1k
else
  size=$Capacity-102400                   # reserve 100M   
fi

Capacity=$size\K
#echo $Capacity

echo "Start testing ..." | tee -a $output   
echo | tee -a $output 

for((i=1;i<=$loopTime;i=i+1))
do

cur_time=`date +%Y-%m-%d\ %H:%M:%S`
timer3=$(date +%s -d "$cur_time")

touch /mnt/io.tst
./fio --filename=/mnt/io.tst --direct=1 --rw=read --ioengine=libaio --bs=128k --iodepth=32 --size=$Capacity --time_based --runtime=1 --name=128K_FillUp >/dev/null 

echo loop $i | tee -a $output  
echo "Filesystem      Size  Used Avail Use% Mounted on" | tee -a $output
df -H | grep -i $target | tee -a $output

rm -rf /mnt/io.tst

cur_time=`date +%Y-%m-%d\ %H:%M:%S`
timer4=$(date +%s -d "$cur_time")
num=$timer4-$timer3
displayTime
echo | tee -a $output
echo "loop $i takes $day day $hour hour $min min $sec sec" | tee -a $output 
echo | tee -a $output
done

umount /mnt

}

cur_time=`date +%Y-%m-%d\ %H:%M:%S`
timer1=$(date +%s -d "$cur_time")
output=`date +%Y%m%d_%H%M%S`.log

libCheck
mainTest

cur_time=`date +%Y-%m-%d\ %H:%M:%S`
timer2=$(date +%s -d "$cur_time")
num=$timer2-$timer1
displayTime

echo "Test Complete." | tee -a $output
echo "Takes $day day $hour hour $min min $sec sec" | tee -a $output 

exit 1
