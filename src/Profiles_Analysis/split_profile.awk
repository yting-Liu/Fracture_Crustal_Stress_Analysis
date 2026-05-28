  BEGIN { 
    file = 1
    outfile = "tmp_profile_1.txt"
  }
  NR == 1 && /Cross/ { next }
  /Cross/ {
    close(outfile)
    file++
    outfile = "tmp_profile_" file ".txt"
    next
  }
  {
    print > outfile
  }
