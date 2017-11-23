//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: IndexStatus.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Stores the status for Search Engine.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//

package mod.se;

public class IndexStatus {
	private static boolean isUpdated = false;
	private static boolean isOptimized = false;
	private static int isCurrentlyUsed = 0;
	
	public static boolean isCurrentlyUsed() {
		if (isCurrentlyUsed > 0)
			return true;
		else
			return false;
	}
	public synchronized static void setCurrentlyUsed(boolean isCurrentlyUsed) {
		if (isCurrentlyUsed)
			IndexStatus.isCurrentlyUsed++;
		else
			IndexStatus.isCurrentlyUsed--;
	}
	public static boolean isOptimized() {
		return isOptimized;
	}
	public synchronized static void setOptimized(boolean isOptimized) {
		IndexStatus.isOptimized = isOptimized;
	}
	public static boolean isUpdated() {
		return isUpdated;
	}
	public synchronized static void setUpdated(boolean isUpdated) {
		IndexStatus.isUpdated = isUpdated;
	}
}
