<?php
header("HTTP/1.0 200 OK");
if (($_GET["login"]==="DiaporamaCenter") && ($_GET["passwd"]==="Test"))
  echo "1";
else
  echo "0";
?>