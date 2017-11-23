<%
////////////////////////////////////////////////////
//	Copyright (c) 2004, eGuanxi, Inc.  All rights reserved.
//
//
//	File:	terms_omf.jsp
//	Author:	ECC
//	Date:	04/22/04
//	Description:
//		Terms.
//	Modification:
//
//
////////////////////////////////////////////////////////////////////
%>

<%@ page import = "util.*" %>

<%
	String NODE			= Util.getPropKey("pst", "PRM_HOST");
	String ADMIN_MAIL	= Util.getPropKey("pst", "FROM");

	boolean isLogin = false;
	String home = request.getParameter("home");
	if (home == null)
		home = "../index.jsp";
	if (home.equals("../ep/ep_home.jsp"))
		isLogin = true;
	
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">

<title>
	MeetWE Terms of Service
</title>

</head>

<%
	String firstName = "";
%>

<body text="#000000" leftmargin="10" topmargin="10" marginwidth="0" marginheight="0">

<!-- BEGIN EXTERNAL TABLE THAT IS LEFT ON PAGE -->
<table width="715" border="0" cellspacing="0" cellpadding="0" align="left">

<!-- TOP BANNER -->
<jsp:include page="infohead.jsp" flush="true" />

<!-- BEGIN INTERNAL CELL -->
<tr>
	<td valign="top">

	<b class="head">

	MeetWE Terms of Service

	</b><br><br>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="headlinerule">
	    <tr>
		<td><img src="/i/spacer.gif" height="1" width="1" alt=" " /></td>
	    </tr>
	</table>
<!-- Navigation SUB-Menu -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
<td width="100%" valign="top">

	<table border="0" width="100%" height="14" cellspacing="0" cellpadding="0">
		<tr>
			<td valign="top" class="bgsubnav">
				<table border="0" cellspacing="0" cellpadding="0">
				<tr class="bgsubnav">
	<!-- Home -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="<%=home%>" class="subnav">Home</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- FAQ -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="faq_omf.jsp?home=<%=home%>" class="subnav">FAQ</a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Terms of Use -->
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="20" height="14"><img src="../i/nav_arrow.gif" width="20" height="14" border="0"></td>
					<td><a href="#" class="subnav" onClick="return false;"><u>Terms of Use</u></a></td>
					<td width="15"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

	<!-- Help Forum -->
					<td width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td><a href="help.jsp?home=<%=home%>" class="subnav">Help Forum</a></td>
					<td colspan="3" width="20"><img src="../i/spacer.gif" width="20" height="1" border="0"></td>
					<td width="7" height="14"><img src="../i/sub_line.gif" width="7" height="14" border="0"></td>

				</tr>
				</table>
			</td>
		</tr>
	</table>
	<table border="0" width="100%" height="1" cellspacing="0" cellpadding="0">
		<tr>
			<td bgcolor="#CCCCCC" width="100%" height="1"><img src="../i/spacer.gif" width="1" height="1" border="0"></td>
		</tr>
	</table>

</td>
</tr>
</table>
<!-- End of Navigation SUB-Menu -->
<!-- CONTENT -->
<table>
	<tr>
		<td width="15">&nbsp;</td>
		<td class="plaintext_head"><br>
		<br>
		
<span class="plaintext">
<ol>

<li>ACKNOWLEDGMENT AND ACCEPTANCE OF TERMS OF SERVICE MeetWE.com ("MeetWE"), owned and operated
by MeetWE, Inc., is provided to you ("Member") under the terms and conditions of
this MeetWE Terms of Service (MTS) and any operating rules or policies that may be published by MeetWE, Inc.
The MTS comprises the entire agreement between Member and MeetWE and supersedes all prior agreements
between the parties regarding the subject matter contained herein.
BY COMPLETING THE REGISTRATION PROCESS, YOU ARE INDICATING YOUR AGREEMENT TO BE BOUND BY ALL
OF THE TERMS AND CONDITIONS OF THE MTS. 
<p>

<li>DESCRIPTION OF SERVICE MeetWE provides Member with various publishing and community services,
including but not limited to the capability to post information to a web page and participate in
web-based discussions and meetings. Some of these services will be free of charge, others may cost money or have
other requirements. The requirements or fees for any service or option will be clearly explained
and separately agreed to when Member implements those options, if any. Member must:
(1) provide all equipment, including a computer and modem, necessary to establish a connection
to the World Wide Web; (2) provide for own access to the World Wide Web and pay any telephone service
fees associated with such access. 
<p>

<li>MODIFICATIONS TO TERMS OF SERVICE MeetWE, Inc. may change the terms and conditions of the MTS from time
to time. Upon major changes in the terms and conditions of the MTS, MeetWE, Inc. will notify you by posting
the changes as a start-up screen prior to your subsequent use of the Service. If you agree to be
bound by the changes, you must again click the "I Accept" button that will follow the posted changes.
If you do not click the "I Accept" button, you may terminate your use of the Service at that time.
Minor changes in the terms and conditions of the MTS will be posted to MeetWE News at
http://www.MeetWE.com. 
<p>
Member's continued use of the Service constitutes an affirmative: (1) acknowledgment by Member
of the MTS and MTS modifications; and (2) agreement by Member to abide and be bound by the MTS
and MTS modifications.
<p>

<li>MODIFICATIONS TO SERVICE MeetWE, Inc. reserves the right to modify or discontinue the Service with or
without notice to Member. MeetWE, Inc. shall not be liable to Member or any third party should MeetWE, Inc.
exercise MTS right to modify or discontinue the Service. 
<p>

<li>PRIVACY POLICY All information entered into MeetWE by Member is private to Member except to
the extent that he or she opts to share that information with other MeetWE members and/or the public,
though MeetWE or otherwise. 
<p>
It is MeetWE, Inc.'s policy to respect the privacy of Members. Therefore, MeetWE, Inc. will not disclose to any
third party Member's name or contact information. MeetWE, Inc. will also not monitor, edit, or disclose
the contents of a Member's information unless required to do so by law or in the good faith belief
that such action is necessary to: (1) conform to the edicts of the law or comply with legal process
served on MeetWE, Inc.; (2) protect and defend the rights or property of MeetWE, Inc.; or (3) act under exigent
circumstances to protect the personal safety of MTS members or the public; (4) fix or debug problems
with the MeetWE software/service. 
<p>

<li>CONTENT OWNERSHIP Unless stated otherwise for specific services, Member will retain copyright
ownership and all related rights for information s/he or publishes through MeetWE or otherwise enters
into MeetWE related services.
<p>

<li>CONTENT RESPONSIBILITY Member acknowledges and agrees that MeetWE, Inc. neither endorses the contents of
any Member communications nor assumes responsibility for any threatening, libelous, obscene,
harassing or offensive material contained therein, any infringement of third party intellectual
property rights arising therefrom or any crime facilitated thereby.
<p>

<li>MEMBER ACCOUNT, PASSWORD, AND SECURITY Once you become a member of the Service, you shall
receive a password and an account. You are entirely responsible if you do not maintain the
confidentiality of your password and account. Furthermore, you are entirely responsible for
any and all activities which occur under your account. You may change your password at any time
(to do so, go to My Profile and update your profile); you may also set up a new account and close an old one
at your convenience. 
<p>
Member agrees to immediately notify MeetWE, Inc. of any unauthorized use of Member's account or any 
other breach of security known to Member. 
<p>

<li>DISCLAIMER OF WARRANTIES MEMBER EXPRESSLY AGREES THAT USE OF THE SERVICE IS AT MEMBER'S SOLE RISK.
THE SERVICE IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS. 
<p>
MEETWE, INC. EXPRESSLY DISCLAIMS ALL WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NON-INFRINGEMENT. 
<p>
MEETWE, INC. MAKES NO WARRANTY THAT THE SERVICE WILL MEET YOUR REQUIREMENTS, OR THAT THE SERVICE WILL BE
UNINTERRUPTED, TIMELY, SECURE, OR ERROR FREE; NOR DOES MAKE ANY WARRANTY AS TO THE RESULTS THAT
MAY BE OBTAINED FROM THE USE OF THE SERVICE OR AS TO THE ACCURACY OR RELIABILITY OF ANY INFORMATION
OBTAINED THROUGH THE SERVICE OR THAT DEFECTS IN THE SOFTWARE WILL BE CORRECTED. 
<p>
MEMBER UNDERSTANDS AND AGREES THAT ANY MATERIAL AND/OR DATA DOWNLOADED OR OTHERWISE OBTAINED
THROUGH THE USE OF THE SERVICE IS DONE AT MEMBER'S OWN DISCRETION AND RISK AND THAT MEMBER WILL
BE SOLELY RESPONSIBLE FOR ANY DAMAGE TO MEMBER'S COMPUTER SYSTEM OR LOSS OF DATA THAT RESULTS
FROM THE DOWNLOAD OF SUCH MATERIAL AND/OR DATA. 
<p>
MEETWE, INC. MAKES NO WARRANTY REGARDING ANY GOODS OR SERVICES PURCHASED OR OBTAINED THROUGH THE
SERVICE OR ANY TRANSACTIONS ENTERED INTO THROUGH THE SERVICE. 
<p>
NO ADVICE OR INFORMATION, WHETHER ORAL OR WRITTEN, OBTAINED BY MEMBER FROM OR THROUGH THE
SERVICE SHALL CREATE ANY WARRANTY NOT EXPRESSLY MADE HEREIN. 
<p>
SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF CERTAIN WARRANTIES, SO SOME OF THE ABOVE
EXCLUSIONS MAY NOT APPLY TO YOU. 
<p>

<li>LIMITATION OF LIABILITY MEETWE, INC. SHALL NOT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL OR CONSEQUENTIAL DAMAGES, RESULTING FROM THE USE OR THE INABILITY TO USE THE SERVICE OR
FOR COST OF PROCUREMENT OF SUBSTITUTE GOODS AND SERVICES OR RESULTING FROM ANY GOODS OR SERVICES
PURCHASE OR OBTAINED OR MESSAGES RECEIVED OR TRANSACTIONS ENTERED INTO THROUGH THE SERVICE OR
RESULTING FROM UNAUTHORIZED ACCESS TO OR ALTERATION OF MEMBER'S TRANSMISSIONS OR DATA,
INCLUDING BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, USE, DATA OR OTHER INTANGIBLE,
EVEN IF HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. 
<p>
SOME JURISDICTIONS DO NOT ALLOW THE LIMITATION OR EXCLUSION OF LIABILITY FOR INCIDENTAL OR
CONSEQUENTIAL DAMAGES SO SOME OF THE ABOVE LIMITATIONS MAY NOT APPLY TO YOU. 
<p>

<li>NO RESALE OF THE SERVICE Member agrees not to resell the Service, without the express
consent of MeetWE, Inc. (Note: Setting up MeetWE Meetings, running Meetings and
maintaining information for clients and charging for your time is fine.) 
<p>

<li>STORAGE AND OTHER LIMITATIONS MeetWE, Inc. assumes no responsibility for the deletion or failure
to store information entered into MeetWE. 
<p>
MeetWE, Inc. has set no fixed upper limit on the number of files and meetings that
Member may send, receive or setup
through the Service or the amount of storage spaced used; however, MeetWE, Inc. retains the right,
at MeetWE, Inc.'s sole discretion, to determine whether or not Member's conduct is consistent with
the letter and spirit of the MTS and may terminate Service if a Member's conduct is found
to be inconsistent with the MTS. 
<p>

<li>MEMBER CONDUCT Member is solely responsible for the contents of his or her transmissions
through the Service. Member's use of the Service is subject to all applicable local, state,
national and international laws and regulations. 
<p>
Member agrees: (1) to comply with US law regarding the transmission of technical data exported
from the United States through the Service; (2) not to use the Service for illegal purposes;
(3) not to interfere or disrupt networks connected to the Service; and (4) to comply with all
regulations, policies and procedures of networks connected to the Service. 
<p>
The Service makes use of the Internet to send and receive certain messages; therefore,
Member's conduct is subject to Internet regulations, policies and procedures. Member will not
use the Service for chain letters, junk mail, spamming or any use of distribution lists to any
person who has not given specific permission to be included in such a process. 
<p>
Member agrees not to transmit through the Service any unlawful, harassing, libelous, abusive,
threatening, or harmful material of any kind or nature. Member further agrees not to transmit
any material that encourages conduct that could constitute a criminal offense, give rise to
civil liability or otherwise violate any applicable local, state, national or international
law or regulation. Attempts to gain unauthorized access to other computer systems are prohibited. 
<p>
Member shall not interfere with another Member's use and enjoyment of the Service or another
entity's use and enjoyment of similar services. 
<p>
MeetWE, Inc. may, at its sole discretion, immediately terminate Service should Member's conduct fail
to conform with these terms and conditions of the MTS. 
<p>

<li>INDEMNIFICATION Member agrees to indemnify and hold MeetWE, Inc., parents, subsidiaries, affiliates,
officers and employees, harmless from any claim or demand, including reasonable attorneys' fees, 
made by any third party due to or arising out of Member's use of the Service, the violation of this 
MTS by Member, or the infringement by Member, or other user of the Service using Member's computer, 
of any intellectual property or other right of any person or entity. 
<p>

<li>TERMINATION Either Member or MeetWE, Inc. may terminate the Service with or without cause at any time 
and effective immediately. MeetWE, Inc. shall not be liable to Member or any third party for termination 
of Service. 
<p>

Should Member object to any terms and conditions of the MTS or any subsequent modifications thereto 
or become dissatisfied with the Service in any way, Member's only recourse is to immediately 
discontinue use of the Service. 
<p>
Upon termination of the Service, Member's right to use the Service and Software immediately ceases. 
Member shall have no right and MeetWE, Inc. will have no obligation thereafter to forward any unread or 
unsent contents to Member or any third party. 
<p>

<li>NOTICE All notices to a party shall be in writing and shall be made either via email or 
conventional mail. MeetWE, Inc. may broadcast notices or messages through the Service to inform Member 
of changes to the MTS, the Service, or other matters of importance; such broadcasts shall 
constitute notice to Member. 
<p>

<li>PARTICIPATION IN PROMOTIONS OF ADVERTISERS Member may enter into correspondence with or 
participate in promotions of the Advertisers showing their products on the Service. Any such 
correspondence or promotions, including the delivery of and the payment for goods and services, 
and any other terms, conditions, warranties or representations associated with such correspondence 
or promotions, are solely between the corresponding Member and the Advertiser. MeetWE, Inc. assumes no 
liability, obligation or responsibility for any part of any such correspondence or promotion. 
<p>

<li>PROPRIETARY RIGHTS TO CONTENT Member acknowledges that content, including but not limited to 
text, software, music, sound, photographs, video, graphics or other material contained in either 
sponsor advertisements or email-distributed, commercially produced information presented to 
Member by the Service ("Content") by MeetWE, Inc. or MeetWE, Inc.'s Advertisers, is protected by copyrights, 
trademarks, service marks, patents or other proprietary rights and laws; therefore, Member 
is only permitted to use this Content as expressly authorized by the Service or the Advertiser. 
Member may not copy, reproduce, distribute, or create derivative works from this Content without 
expressly being authorized to do so by the Service or the Advertiser. 
<p>

<li>LAWS The MTS shall be governed by and construed in accordance with the laws of the state 
of California, excluding MTS conflict of law provisions. 
<p>

<li>Member and MeetWE, Inc. agree to submit to the exclusive jurisdiction of the courts of the state 
of California. If any provision(s) of the MTS is held by a court of competent jurisdiction 
to be contrary to law, then such provision(s) shall be construed, as nearly as possible, to 
reflect the intentions of the parties with the other provisions remaining in full force and effect. 
<p>
MeetWE, Inc.'s failure to exercise or enforce any right or provision of the MTS shall not constitute 
a waiver of such right or provision unless acknowledged and agreed to by MeetWE, Inc. in writing. 
<p>
Member and MeetWE, Inc. agree that any cause of action arising out of or related to this Service 
must commence within one (1) year after the cause of action arose; otherwise, such cause 
of action is permanently barred. The section titles in the MTS are solely used for the 
convenience of the parties and have no legal or contractual significance.
<p>
</ol>
</span>

</td></tr>
<tr><td>&nbsp;</td><tr>
</table>



<table width="100%">
<!-- BEGIN FOOTER TABLE -->
<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="780" height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
    <td height="2" bgcolor="336699"><img src="../i/mid/u2x2.gif" width="2" height="2"></td>
  </tr>
  <tr>
    <td width="780" valign="middle" align="center">
		<a href="<%=home%>" class="listlink">Home</a>
		&nbsp;|&nbsp;
		<a href="help.jsp?home=<%=home%>" class="listlink">Help forum</a>
		&nbsp;|&nbsp;
		<a href="privacy_omf.jsp" class="listlink">Privacy Statement</a>
<%if (isLogin){%>
		&nbsp;|&nbsp;
		<a href="../logout.jsp" class="listlink">Logout</a>
<%}%>
		&nbsp;|&nbsp;
		<a href="#top" class="listlink">Back to top</a></td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td width="780" height="32" align="center" valign="middle"><font size="1" face="Arial, Helvetica, sans-serif" color="#999999" class="8ptype">Copyright
      &copy; 2006, MeetWE</font></td>
    <td height="32">&nbsp;</td>
  </tr>
</table>
<!-- END FOOTER TABLE -->



<!-- END INTERNAL CELL -->

</table>
<!-- END EXTERNAL TABLE THAT IS CENTERED ON PAGE -->

</body>
</html>

