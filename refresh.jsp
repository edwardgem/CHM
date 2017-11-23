<html>
<META HTTP-EQUIV="Refresh" CONTENT="10">
<body>
<%
	int i=0;
	String ii = (String) session.getValue("count");
      if (ii!=null) {
		i = Integer.parseInt(ii);
		out.println("<h1>Counter is: "+i+"<h1>" );
	      i++;
	}
      session.putValue("count",new Integer(i).toString());
%>
</body>
</html>

