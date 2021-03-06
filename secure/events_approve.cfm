<cfif parameterexists(form.criteria)>
  <cfset url.criteria=form.criteria>
  <cfelseif  parameterexists(url.criteria) EQ 0>
  <cfset url.criteria='none'>
</cfif>

<!--sort nav variables	(variables passed through sortnav in templates folder)-->
<cfparam name="variables.sortby" default="created">
<cfif isDefined("url.sortby")>
  <cfset sortby=(url.sortby)>
  <cfelse>
  <cfset sortby='startdate'>
</cfif>
<cfparam name="site" default="0">
<cfif isDefined("url.site")>
  <cfset site=(url.site)>
  <cfelse>
  <cfset site=0>
</cfif>
<cfif isDefined("url.select1") and select1 EQ 1>
  <cfset where='to_char(startdate, *yyyy-mm-dd*) >= to_char(SYSDATE, *yyyy-mm-dd*)'>
  <cfset where=replace(where,"*","#Chr(39)#","all")>
  <cfset select1=1>
  <cfelseif isDefined("url.select1") and select1 EQ 2>
  <cfset where='to_char(startdate, *yyyy-mm-dd*) <= to_char(SYSDATE, *yyyy-mm-dd*)'>
  <cfset where=replace(where,"*","#Chr(39)#","all")>
  <cfset select1=2>
  <cfelseif isDefined("url.select1") and select1 EQ 3>
  <cfset where='0=0'>
  <cfset select1=3>
  <cfelse>
  <cfset where='to_char(startdate, *yyyy-mm-dd*) >= to_char(SYSDATE, *yyyy-mm-dd*)'>
  <cfset where=replace(where,"*","#Chr(39)#","all")>
  <cfset select1=1>
</cfif>
<!--end sort nav variables	-->

<cfquery name="getevents" datasource="#application.datasource_select#">
		SELECT      users.lastname, users.firstname, users.user_admin,events_tbl.startdate, sites.site_name, events_tbl.pubdate, events_tbl.pulldate, events_tbl.eventid, events_tbl.shortdesc, events_tbl.userid, event_refid, INFO_CLOB as information,longdesc,events_link,events_link_override,sponsor,contact,contactinfo,specificlocation,locationid,events_tbl.ispublic,invited,events_cost as cost, sites.siteid,created
		FROM         CUNVMCS.events_tbl, CUNVMCS.events_ref, CUNVMCS.sites, CUNVMCS.users 
		WHERE       events_tbl.eventid = events_ref.eventid AND  events_tbl.isactive=1 AND events_ref.siteid = sites.siteid AND events_tbl.userid = users.userid and events_ref.events_ref_level=1 and sites.isactive=1			
		AND #preservesinglequotes(variables.where)#
        <cfif url.criteria neq 'none'>and (LOWER(events_tbl.shortdesc) like LOWER('%#url.criteria#%') OR LOWER(users.firstname) like LOWER('%#url.criteria#%') OR LOWER(users.lastname) like LOWER('%#url.criteria#%') OR dbms_lob.instr(INFO_CLOB,'#url.criteria#')>0 OR LOWER(events_tbl.sponsor) like LOWER('%#url.criteria#%') OR LOWER(events_tbl.contact) like LOWER('%#url.criteria#%') <cfif isdate(url.criteria)><cfset url.criteria2=createodbcdate(url.criteria)>or to_char(startdate, 'yyyy-mm-dd') = to_char(#url.criteria2#, 'yyyy-mm-dd')</cfif>)</cfif>
		<cfif session.administrator eq 0>and  events_ref.siteid IN (#session.publish#)
		</cfif>
		order by #variables.sortby#
        
        
        
	</cfquery>

<!--- Pagination Variables --->
<cfset limit=20>
<cfset pagelimit=10>
<cfif isDefined("url.page") and url.page neq 1>
  <cfset page=#url.page#>
  <cfset pagestart=(page*limit)-(limit-1)>
  <cfelse>
  <cfset page=1>
  <cfset pagestart=1>
</cfif>
<cfset totalrows=getevents.recordcount>
<cfset limitvalue=page*limit>
<cfset numofpages = totalrows/limit>
<cfif numofpages gt pagelimit AND page gte 7>
  <cfset loopstart=page-5>
  <cfset loopend=page+5>
  <cfif loopend gt numofpages>
    <cfset loopend=numofpages>
  </cfif>
  <cfelseif numofpages gt pagelimit AND page lt 7>
  <cfset loopstart=1>
  <cfset loopend=pagelimit>
  <cfelse>
  <cfset loopstart=1>
  <cfif numofpages gt int(numofpages)>
    <cfset numofpages=int(numofpages)+1>
  </cfif>
  <cfset loopend=numofpages>
</cfif>
<cfset pageprev=page-1>
<cfset pagenext=page+1>
<!--- end pagination variables --->

<cfset sort='yes'>
<cfinclude template="templates/top.cfm">
      <h1>Approve Events</h1>
      <cfinclude template="templates/filter.cfm">
      
      <!---Success for Action Start--->
	  <cfif isdefined("url.event_refid")>
    	<cfquery name="getsuccess" datasource="#application.datasource_select#">
		SELECT      users.lastname, users.firstname, users.user_admin,events_tbl.startdate, sites.site_name, events_tbl.pubdate, events_tbl.pulldate, events_tbl.eventid, events_tbl.shortdesc, events_tbl.userid, event_refid
		FROM         CUNVMCS.events_tbl, CUNVMCS.events_ref, CUNVMCS.sites, CUNVMCS.users 
		WHERE       events_tbl.eventid = events_ref.eventid AND  events_tbl.isactive=1 AND events_ref.siteid = sites.siteid AND events_ref.userid = users.userid 	
		AND events_ref.event_refid=#url.event_refid#
		</cfquery>    
    	<div id="myAlert" class="alert alert-success fade" data-alert="alert">
          <button type="button" class="close" data-dismiss="alert">&times;</button>
          <strong>Event Approved</strong>
          <cfoutput>#getsuccess.shortdesc# published to #getsuccess.site_name#</cfoutput>
        </div>
      </cfif>
      <script src="js/adjust.js"></script> 
      
	  <!---Success for Action End--->
      
      <table class="table table-striped table-hover">
    <cfoutput><thead>
          <tr>
        <th class="<cfif variables.sortby eq 'shortdesc'>selected</cfif>"><a href="#variables.location#?startindex=#variables.pagestart#&select1=#variables.select1#&site=#variables.site#&sortby=shortdesc&criteria=#criteria#">Title</a></th>
              <th class="hidden-phone <cfif variables.sortby eq 'lastname'>selected</cfif>"><a href="#variables.location#?startindex=#variables.pagestart#&select1=#variables.select1#&site=#variables.site#&sortby=lastname&criteria=#criteria#">Author</a></th>
              <th class="hidden-phone <cfif variables.sortby eq 'startdate desc'>selected</cfif>"><a href="#variables.location#?startindex=#variables.pagestart#&select1=#variables.select1#&site=#variables.site#&sortby=startdate desc&criteria=#criteria#">Event Date</a></th>
        <th class="hidden-phone <cfif variables.sortby eq 'created'>selected</cfif>"><a href="#variables.location#?startindex=#variables.pagestart#&select1=#variables.select1#&site=#variables.site#&sortby=created&criteria=#criteria#">Create Date</a></th>
        <th <cfif variables.sortby eq 'created'>selected</cfif>"><a href="#variables.location#?startindex=#variables.pagestart#&select1=#variables.select1#&site=#variables.site#&sortby=site_name&criteria=#criteria#">Site</a></th>
        <th>Actions</th>
      </tr>
        </thead></cfoutput>
    <cfif getevents.recordcount is 0>
          <tr>
        <td colspan=5>There are no events  waiting to be published to your sites with this criteria</td>
      </tr>
          <cfelse>
          <cfoutput query="getevents" startrow=#pagestart# maxrows=#limit#>
        <form action="events_action.cfm?page=#variables.page#" method="post">
              <tr>
            <td><a href="##myModal#currentrow#" data-toggle="modal">#shortdesc#</a></td>
            <td class="hidden-phone">#firstname# #lastname#
                  <cfif user_admin is 1>
                *
              </cfif></td>
            <td class="hidden-phone">#dateformat(startdate,"mm.dd.yyyy")#</td>
            <td class="hidden-phone">#dateformat(created,"mm.dd.yyyy")#</td>
            <td>#site_name#</td>
            <td><button type="submit" name="publishsite" class="btn btn-small"><i class="icon-ok"></i> Approve</button>
             <button type="submit" name="reject" class="btn btn-small"> <i class="icon-remove"></i> Reject </button>
                  <cfif session.administrator is 1 or getevents.userid eq session.userid>
                <button type="submit" name="rework" value="rework" class="btn btn-small"> <i class="icon-pencil"></i> Edit </button>
              </cfif></td>
          </tr>
              <input type="hidden" name="eventid" value="#eventid#">
              <input type="hidden" name="siteid" value="#siteid#">
              <input type="hidden" name="site_name" value="#site_name#">
              <input type="hidden" name="shortdesc" value="#shortdesc#">
              <input type="hidden" name="event_refid" value="#event_refid#">
            </form>
            <!-- Modal -->
<div id="myModal#currentrow#" class="modal hide" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
  <div class="modal-header">
    <button type="button" class="close" data-dismiss="modal" aria-hidden="true">x</button>
    <h4 id="myModalLabel">#shortdesc#</h4>
  </div>
  <div class="modal-body">
<cfinclude template="templates/events_add_set.cfm">	
  <cfinclude template="templates/events_layout.cfm"> 
  <ul>
   	<li>Publish Date: #dateformat(pubdate,"mm.dd.yyyy")# #timeformat(pubdate,"hh:mm")#</li>
	<li>Pull Date:#dateformat(pulldate,"mm.dd.yyyy")# #timeformat(pulldate,"hh:mm")#</li>
	</ul>  <!--- --->
  </div>
  <div class="modal-footer">
    <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
  </div>
</div>
      </cfoutput>
        </cfif>
  </table>
      
      <!--Pagination row--> 
      <cfoutput>
    <div class="pagination">
          <ul>
        <cfif variables.page NEQ 1>
              <li><a href="#cgi.SCRIPT_NAME#?page=#pageprev#&criteria=#criteria#&sortby=#variables.sortby#&select1=#variables.select1#" class="previous">&lt;&lt; Previous</a></li>
            </cfif>
        <cfloop index="i" from="#loopstart#" to="#loopend#">
              <cfif i EQ variables.page>
            <li class="active"><a href="#cgi.SCRIPT_NAME#?page=#i#&criteria=#criteria#&sortby=#variables.sortby#&select1=#variables.select1#">#i#</a></li>
            <cfelse>
            <li><a href="#cgi.SCRIPT_NAME#?page=#i#&criteria=#criteria#&sortby=#variables.sortby#&select1=#variables.select1#">#i#</a></li>
          </cfif>
            </cfloop>
        <cfif variables.page NEQ numofpages>
              <li> <a href="#cgi.SCRIPT_NAME#?page=#pagenext#&criteria=#criteria#&sortby=#variables.sortby#&select1=#variables.select1#" class="next">Next &gt;&gt;</a></li>
            </cfif>
      </ul>
        </div>
    <!--end pagination table row--> 
  </cfoutput>
      <cfinclude template="templates/bottom.cfm">
