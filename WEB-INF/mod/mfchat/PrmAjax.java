package mod.mfchat;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import oct.codegen.action;
import oct.codegen.actionManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.PrmLog;

public class PrmAjax extends HttpServlet {
	
	private static final long serialVersionUID = 1L;
	private static final String ID		= "id";
	private static final String B_ARG1	= "bArg1";
	private static final String D_ARG1	= "dtArg1";
	
	// operations
	private static final String OP		= "op";
	private static final String SET_ACTION_DONE	= "SET_ACTION_DONE";	// not used
	private static final String SET_ACTION_DUE	= "SET_ACTION_DUE";		// set action due date
	
	// support Python calls
	private static final String PY_ACTION_1		= "PY_ACTION_1";
	
	private static final SimpleDateFormat df1 = new SimpleDateFormat("MM/dd/yy");
	
	private static Logger l;
	private static actionManager aMgr;
	
	static {
		l = PrmLog.getLog();
		try {
			aMgr = actionManager.getInstance();
		}
		catch (PmpException e) {
			l.error("PrmAjax failed to init.");
		}
	}
	
	
	public void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		System.out.println("PrmAjax.doGet()");
	}
	
	
	public void doPost(HttpServletRequest request, HttpServletResponse response) 
			throws ServletException, IOException {

		System.out.println("here ....");
		String op = request.getParameter(OP);
		String id = request.getParameter(ID);
		
		System.out.println("PrmAjax.doPost(), op=" + op);
		
		// Get the current session and pstuser 
		PstUserAbstractObject u = null;
		HttpSession httpSession = request.getSession(false);
		// Verify that this is indeed the user
		// Check valid user
		if (httpSession != null)
			u = (PstUserAbstractObject)httpSession.getAttribute("pstuser");
		
		try {
			// set the action item to done or re-open
			if (op.equals(SET_ACTION_DONE)) {
				action aObj = (action) aMgr.get(u, id);
				String status;
				
				boolean bArg1 = new Boolean(request.getParameter(B_ARG1));

				if (bArg1) {
					status = action.DONE;
				}
				else {
					status = action.OPEN;
				}
				aObj.setStatus(u, status);		// commit or re-open
				l.info("PrmAjax.doPost() completed successfully: op=" + op + "; id=" + id + "; st=" + status);
			}
			
			// set action due date
			else if (op.equals(SET_ACTION_DUE)) {
				action aObj = (action) aMgr.get(u, id);

				Date dt1 = null;
				String s = request.getParameter(D_ARG1);
				try {dt1 = df1.parse(s);}
				catch (java.text.ParseException e) {e.printStackTrace();}
				
				if (dt1 != null) {
					aObj.setAttribute("ExpireDate", dt1);
					aMgr.commit(aObj);
				}
				l.info("PrmAjax.doPost() completed successfully: op=" + op + "; id=" + id + "; dt=" + dt1);
			}
			
			///////////////////////////////////////////////////////////
			// Python calls
			
			else if (op.equals(PY_ACTION_1)) {
				String words = request.getParameter("words");
				System.out.println("Words: " + words);

				l.info("PrmAjax.doPost() for Python completed successfully: op=" + op);
			}
		}
		catch (PmpException e) {
			l.error("Caught PmpException in PrmAjax.doPost(): op=" + op + "; id=" + id);
			e.printStackTrace();
		}
	}
}
