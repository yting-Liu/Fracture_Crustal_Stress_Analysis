#!/bin/csh -f

set width = 3000
mkdir -p ../profiles

#rm tmp*
rm ../profiles/*
set i = 0
set k = 1
set s = 0
set ct = 0
awk '{print $1","$2}' ../data/fractures.gmt > tmp_fractures.gmt
#awk '{print $1","$2}' test.gmt > tmp_test.gmt
foreach line (`cat tmp_fractures.gmt`)
#foreach line (`cat tmp_test.gmt`)
  echo $line
  set n = `echo $line | awk '{print substr($1,4,1)}'`
  if ($n == "L") then
  echo $n $i
    if ($i == 1) then
      echo "setting s to 0..."
      set s = 0
    else
      echo "setting i to 1..."
      set i = 1
    endif
  else
    if ($s == 0) then
      set ll1 = $line
      echo $line $s $i $n
      set k = 2
      set s = 1
    else if ($k == 2) then
      set ll2 = $line
      set lon1 = `echo $ll1 | awk -F, '{print $1}'`
      set lat1 = `echo $ll1 | awk -F, '{print $2}'`
      set lon2 = `echo $ll2 | awk -F, '{print $1}'`
      set lat2 = `echo $ll2 | awk -F, '{print $2}'`
      echo $lon1 $lat1 > tmp
      echo $lon2 $lat2 >> tmp

      set ct = `echo $ct | awk '{printf("%.4d",$1+1)}'`
      echo "Working on segment $ct"_"$lon1"_"$lat1"_"$lon2"_"$lat2.txt"      

      set spacing = `echo $lon1 $lat1 $lon2 $lat2 | awk '{print 0.5*100000*sqrt(($1-$3)*($1-$3)+($2-$4)*($2-$4))}'`
      #set sp = `echo $spacing | awk '{printf("%d",$1)}'`
      #if ($sp > 200) set spacing = 200

      gmt grdtrack tmp -G../data/EW.grd -C$width"e/20e/"$spacing"e+v" -Ar > tmp2
      set n2 = `grep -n Cross tmp2 | awk -F: 'NR==2{print $1-1}'`
      set pll1 = `awk 'NR==2{print $1}' tmp2`
      set plt1 = `awk 'NR==2{print $2}' tmp2`
      set pll2 = `awk 'NR=='$n2'{print $1}' tmp2`
      set plt2 = `awk 'NR=='$n2'{print $2}' tmp2`

      awk -f split_profile.awk tmp2

      #grep -v Cross tmp2 | awk '{print $3,$5}' | sort -n | gmt filter1d -Fm30 | gmt trend1d -Fxr -Np1r > tmp.xy
      set num = 1
      foreach f (tmp_profile_*.txt)
        cat $f | awk '{print $3,$5}' | sort -n > tmp.dis
        gmt sample1d tmp.dis -Fl -I20 > tmp_resam
          if ($num == 1) then
            gmt math tmp_resam = tmp_sum
          else
            gmt math tmp_resam tmp_sum ADD = tmp_sumtmp
            mv tmp_sumtmp tmp_sum
          endif
        @ num ++
      end

      #set count = `ls tmp_profile_* | wc -l`
      @ num --
      gmt math tmp_sum $num DIV = tmp_aver
      cat tmp_aver | awk '!($1 ~ /NaN/ || $2 ~ /NaN/)' | gmt trend1d -Fxr -Np1r > tmp.xy

      mv tmp.xy  ../profiles/$ct"_"$lon1"_"$lat1"_"$lon2"_"$lat2"_"$pll1"_"$plt1"_"$pll2"_"$plt2
      rm tmp_profile_*
      
      set ll1 = $ll2
      set k = 2
    endif
  endif
end

rm tmp*

