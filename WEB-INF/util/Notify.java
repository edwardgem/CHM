package util;
import java.util.Properties;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.Message.RecipientType;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.util.*;
//By Perry
public class Notify{

public static void SendEmail(String From,String To,String Subject,String Content,String From_name) throws Exception{
System.out.println("Start to Send Email=======");
Properties props1=new Properties();
props1.setProperty("mail.smtp.auth", "true");//必须 普通客户端
props1.setProperty("mail.transport.protocol", "smtp");//必须选择协议
props1.setProperty("mail.host", "mail.hku-szh.org");
Session session=Session.getDefaultInstance(props1,
new Authenticator(){
@Override
protected PasswordAuthentication getPasswordAuthentication() {
return new PasswordAuthentication("notify_wf@hku-szh.org","hkuszh868");
}
});
session.setDebug(false);
Message msg1=new MimeMessage(session);
msg1.setFrom(new InternetAddress(From,From_name));
msg1.setSubject(Subject);
msg1.setRecipients(RecipientType.TO,InternetAddress.parse(To) );//多个收件人
msg1.setContent(Content, "text/html;charset=gbk");
msg1.setSentDate(new Date());
Transport.send(msg1);
System.out.println("Send Email Successfully=======");
}

}
