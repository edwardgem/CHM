/**
 * 
 */
package util;

import oct.pst.PstFlow;
import oct.pst.PstFlowDataObject;
import oct.pst.PstSystem;

import org.apache.log4j.Logger;

/**
 * @author edwardc
 *
 */
public class EndFlow {
	private static Logger l = PrmLog.getLog();
	
	public Boolean notifyUser(PstFlowDataObject flowDataObj)
	{
		try {
			// send notification email to user
			if (flowDataObj != null) {
				l.info("EndFlow: flow data id=" + flowDataObj.getObjectId());
			}
			else {
				l.info("EndFlow: flow data is NULL");
			}
			PstSystem pst = PstSystem.getInstance();
			PstFlow flowObj = PrmWf.getFlowInstanceFromDataObject(pst, flowDataObj);
			String subject = "[IT Alert]";
			
			// we should get the message from the IT Handle person and send it to the user
			String message = "Your machine is ready to be picked up.";
			
			PrmWf.notifyFlowInitiator(pst, flowObj, subject, message);
			
			// all done
			l.info(">>> Plugin class EndFlow.notifyUser() is done!");
			return new Boolean(true);
		}
		catch(Exception e) {
			e.printStackTrace();
			l.error("Exception in EndFlow.notifyUser()\n" + e.toString());
			return new Boolean(false);
		}
	}
}
