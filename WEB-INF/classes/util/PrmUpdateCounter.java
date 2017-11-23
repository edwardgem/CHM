package util;

import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;


public class PrmUpdateCounter implements PrmMtgConstants{
	private static HashMap updateCounters = new HashMap();
	
//	**************************************************
//	* HashMap Counter Helpers
//	**************************************************
	
	/**
	 * Checks hashMap, updateCounter, for existing of midS. If it does not
	 * exist, create an int[] initialized to 0.
	 * @param midS Meeting ID
	 * @return true if successfully created; false if one already exists
	 */
	synchronized private static boolean createCounterArray(String midS) {
		if(updateCounters.containsKey(midS))
			return false;
		else {
			int[] counters = new int[ARRAYSIZE];
			for(int i = 0; i < ARRAYSIZE; i++)
				counters[i] = 0;
			updateCounters.put(midS, counters);
			return true;
		}		
	}
	
	/**
	 * Tries to update the counter array if it exists. If it does not, create one
	 * and try to update again. 
	 * @param midS
	 * @param type
	 * @return true
	 */
	synchronized public static boolean updateOrCreateCounterArray(String midS, int type) {
		if(!updateCounterArray(midS, type)) {
			// Try to create a new counterArray into HashMap and update
			if(createCounterArray(midS))
				return updateCounterArray(midS, type); 
			// Failed to create new counterArray into HashMap
			else
				return false;
		}
		else 
			return true; // Successful
	}
	
	/**
	 * Checks to see if a counter array exists for current meeting. If it
	 * exists, update the counters. If it does not exist or the counter
	 * array is bad create a new one. 
	 * @param midS
	 * @param type
	 * @return true - update is successful; false could not be updated
	 */
	synchronized private static boolean updateCounterArray(String midS, int type) {
		if(updateCounters.containsKey(midS)) {
			int[] counters;
			Object obj = updateCounters.get(midS);
			if(obj != null) {
				counters = (int[])obj;
				if(counters.length == ARRAYSIZE) {
					counters[type]++;
					return true;
				}
			}
			// Bad counter array; Remove it
			removeCounterArray(midS);
		}
		return false; // Could not update or create array
	}
	
	/**
	 * Remove the Counter Array for meeting midS. Used when the meeting has adjourn
	 * @param midS
	 * @return true if remove was successful; false if object did not exist
	 */
	synchronized public static boolean removeCounterArray(String midS) {
		if(updateCounters.containsKey(midS)) {
			updateCounters.remove(midS);
			return true;
		}
		return false;
	}
	
	/**
	 * Checks to see if the current user's counters require an update
	 * @param midS
	 * @param userCounters
	 * @return flag with the bit value set to require update
	 */
	synchronized public static int checkUpdateCounters(String midS, int[] userCounters, int[] localCounters) {
		int flag = 0;
		// Check to make sure that a different array was not used
		if(localCounters.length == ARRAYSIZE && userCounters.length == ARRAYSIZE) {
			for(int i = 0 ; i < ARRAYSIZE; i++) {
				// flag the bit if the counters do not match
				if(localCounters[i] != userCounters[i]) {
					flag = flag | getBit(i); // union of flag and bit value
				}
			}
		}
		return flag;
	}
	
	/**
	 * Localizes the counters so the user will not get any different value.
	 * Loops through the counters and sets it into a local int[]. If the 
	 * counter for this midS has not been created yet, 0 is returned for all
	 * the counters.
	 * @param midS
	 * @return a local version of the counter
	 */
	public static int[] getMtgCounters(String midS) {
		Object obj = updateCounters.get(midS);
		int[] syncCounter = (obj == null)?null:(int[])obj;
		int[] localCounter = new int[ARRAYSIZE];
		if (syncCounter != null) {
			// Localize the counters so any update will not change it. 
			for (int i = 0; i < ARRAYSIZE; i++) {
				localCounter[i] = syncCounter[i];
			}
		}
		else {
			// Initialize everything to zero
			for (int i = 0; i < ARRAYSIZE; i++) {
				localCounter[i] = 0;
			}
		}
		return localCounter;
	}
	
	/**
	 * Receives the counters from the user, if the variables does not
	 * exist, 0 will be used.
	 * @param request
	 * @return int[] of user's counters; or int[] of 0 is non exist
	 */
	public static int[] getUserCounters(HttpServletRequest request) {
		// TODO: make this method split , from user
		int[] userCounters = new int[ARRAYSIZE];
		String temp;
		for(int i = 0; i < ARRAYSIZE; i++) {
			temp = request.getParameter(getJsName(i));
			if(temp != null && temp.length() > 0) {
				userCounters[i] = Integer.parseInt(temp);
			}
			else
				userCounters[i] = 0;
		}
		return userCounters;
	}
	
	/**
	 * Method to return the js variable name according to the index. 
	 * @param i
	 * @return js's variable name
	 */
	private static String getJsName(int i) {
		switch(i) {
		case ADINDEX: 
			return ADCOUNT; 
		case ATINDEX:
			return ATCOUNT;
		case MNINDEX:
			return MNCOUNT;
		case AIINDEX:
			return AICOUNT;
		case DCINDEX:
			return DCCOUNT;
		case ISINDEX:
			return ISCOUNT;
		case ININDEX:
			return INCOUNT;
		case UDINDEX:	// @AGQ101106
			return UDCOUNT;
		}
		return null;
	}
	
	/**
	 * Method to return the corresponding bits according to the index provided.
	 * Any new counters that needs to be set will be modified here.
	 * i.e. int 0 = 1, int 1 = 2, int 2 = 4, int 3 = 8... 
	 * @param i
	 * @return bit value for index
	 */
	private static int getBit(int i) {
		switch(i) {
		case ADINDEX: 
			return ADBIT; 
		case ATINDEX:
			return ATBIT;
		case MNINDEX:
			return MNBIT;
		case AIINDEX:
			return AIBIT;
		case DCINDEX:
			return DCBIT;
		case ISINDEX:
			return ISBIT;
		case ININDEX:
			return INBIT;
		case UDINDEX:	// @AGQ101106
			return UDBIT;
		}
		return 0;
	}
}
