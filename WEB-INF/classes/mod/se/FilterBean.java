//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: FilterBean.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine Filter object bean.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import oct.codegen.result;

public class FilterBean {
	// TODO: need to decide if creating a hashmap will be better instead of variables
	private String type;
	private int projectID;
	private String fromDate;
	private String toDate;
	private String postName;
	private String accessName;
	private String [] queryBlogType;
	
	public FilterBean() {
		type = null;
		projectID = 0;
		fromDate = null;
		toDate = null;
		postName = null;
		accessName = null;
		queryBlogType = new String[3];
		for (int i=0; i<queryBlogType.length; i++) {
			queryBlogType[i] = null;
		}
	}
	
	public FilterBean(String filter) {
		this();
		
		String [] filterArr = null;
		if (filter != null && filter.length() > 0) {
			filterArr = filter.split("&"); // Split all parameters
			for (int i=0; i<filterArr.length; i++) {
				String curFilter = filterArr[i].trim();
				if (curFilter.length() > 0) {
					String [] paramArr = curFilter.split("="); // Split name and value
					// Value will not have any special characters like =
					if (paramArr.length == 2) { 
						String name = paramArr[0].trim();
						String value = paramArr[1].trim();
						if (value.length() > 0) {
							if (name.equalsIgnoreCase("projName")) 
								projectID = Integer.parseInt(value);
							else if (name.equalsIgnoreCase("FromDate"))
								fromDate = value;
							else if (name.equalsIgnoreCase("ToDate"))
								toDate = value;
							else if (name.equalsIgnoreCase("postName"))
								postName = value;
							else if (name.equalsIgnoreCase("accessName"))
								accessName = value;
							else if (name.equalsIgnoreCase(result.TYPE_BUG_BLOG))
								queryBlogType[0] = result.TYPE_BUG_BLOG;
							else if (name.equalsIgnoreCase(result.TYPE_TASK_BLOG))
								queryBlogType[1] = result.TYPE_TASK_BLOG;
							else if (name.equalsIgnoreCase(result.TYPE_ACTN_BLOG))
								queryBlogType[2] = result.TYPE_ACTN_BLOG;
						}
					}
				}
			}
		}
	}
	
	public String getAccessName() {
		return accessName;
	}

	public void setAccessName(String accessName) {
		this.accessName = accessName;
	}

	public String getFromDate() {
		return fromDate;
	}

	public void setFromDate(String fromDate) {
		this.fromDate = fromDate;
	}

	public String getPostName() {
		return postName;
	}

	public void setPostName(String postName) {
		this.postName = postName;
	}

	public int getProjectID() {
		return projectID;
	}

	public void setProjectID(int projectID) {
		this.projectID = projectID;
	}

	public String getToDate() {
		return toDate;
	}

	public void setToDate(String toDate) {
		this.toDate = toDate;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String[] getQueryBlogType() {
		return queryBlogType;
	}

	public void setQueryBlogType(String[] queryBlogType) {
		this.queryBlogType = queryBlogType;
	}
}
