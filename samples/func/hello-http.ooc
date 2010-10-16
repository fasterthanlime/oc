
socket := ServerSocket("0.0.0.0", 80)
loop(->
  conn := socket accept()
  go(->
    5 times(->
      conn out write("<html><body>Hi, world!</body></html>")
    )
    conn close()
  )
)
