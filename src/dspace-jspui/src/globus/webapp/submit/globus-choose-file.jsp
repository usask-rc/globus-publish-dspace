<%--
* This file is a modified version of a DSpace file.
* All modifications are subject to the following copyright and license.
* 
* Copyright 2016 University of Chicago. All Rights Reserved.
* 
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
* 
* http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
--%>


<%--

    The contents of this file are subject to the license and copyright
    detailed in the LICENSE and NOTICE files at the root of the source
    tree and available online at

    http://www.dspace.org/license/

--%>
<%@ page contentType="text/html;charset=UTF-8" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt"
    prefix="fmt" %>

 <%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>

<%@ taglib uri="http://www.dspace.org/dspace-tags.tld" prefix="dspace" %>

<%@ page import="javax.servlet.jsp.jstl.fmt.LocaleSupport" %>

<%@ page import="java.util.List" %>
<%@ page import="org.dspace.core.ConfigurationManager" %>
<%@ page import="org.dspace.core.Context" %>
<%@ page import="org.dspace.content.Item" %>
<%@ page import="org.dspace.app.webui.servlet.SubmissionController" %>
<%@ page import="org.dspace.authorize.ResourcePolicy" %>
<%@ page import="org.dspace.submit.AbstractProcessingStep" %>
<%@ page import="org.dspace.submit.step.UploadStep" %>
<%@ page import="org.dspace.app.util.DCInputSet" %>
<%@ page import="org.dspace.app.util.DCInputsReader" %>
<%@ page import="org.dspace.app.util.SubmissionInfo" %>
<%@ page import="org.dspace.app.webui.util.UIUtil" %>
<%@ page import="org.dspace.globus.Globus" %>


<%
    request.setAttribute("LanguageSwitch", "hide");

    // Obtain DSpace context
    Context context = UIUtil.obtainContext(request);

    //get submission information object
    SubmissionInfo subInfo = SubmissionController.getSubmissionInfo(context, request);

    int resumeId = subInfo.getSubmissionItem().getID();
    int itemId = subInfo.getSubmissionItem().getItem().getID();
    Item item = subInfo.getSubmissionItem().getItem();
	String endpoint = Globus.encodeSharedEndpointName(item.getGlobusEndpoint());
	String path =  item.getGlobusSharePath();
	String pathToData = Globus.getPathToData(item);

    boolean withEmbargo = ((Boolean)request.getAttribute("with_embargo")).booleanValue();

    // Determine whether a file is REQUIRED to be uploaded (default to true)
    // Globus changed to false
    boolean fileRequired = ConfigurationManager.getBooleanProperty("webui.submit.upload.required", false);
    boolean ajaxProgress = ConfigurationManager.getBooleanProperty("webui.submit.upload.ajax", true);

 	Boolean sherpa = (Boolean) request.getAttribute("sherpa");
    boolean bSherpa = sherpa != null?sherpa:false;

    if (ajaxProgress || bSherpa)
    {
%>
<c:set var="dspace.layout.head.last" scope="request">
<%
     if (bSherpa) { %>

	<link rel="stylesheet" href="<%=request.getContextPath()%>/sherpa/css/sherpa.css" type="text/css" />
	<script type="text/javascript">
		jQuery(document).ready(function(html){
			jQuery.ajax({
				url: '<%= request.getContextPath() + "/tools/sherpaPolicy" %>',
				data: {item_id: <%= subInfo.getSubmissionItem().getItem().getID() %>}})
					.done(function(html) {
						jQuery('#sherpaContent').html(html);
			});
		});
	</script>
	<% }
	if (ajaxProgress) { %>
	<link rel="stylesheet" href="<%= request.getContextPath() %>/static/css/jquery.fileupload-ui.css">
	<!-- CSS adjustments for browsers with JavaScript disabled -->
	<noscript><link rel="stylesheet" href="<%= request.getContextPath() %>/static/css/jquery.fileupload-ui-noscript.css"></noscript>
    <script type="text/javascript">
		var bootstrapButton = $.fn.button.noConflict(); // return $.fn.button to previously assigned value
		$.fn.bootstrapBtn = bootstrapButton;            // give $().bootstrapBtn the Bootstrap functionality

	function initProgressBar($){
    	var progressbarArea = $("#progressBarArea");
		progressbarArea.show();
    }

    function updateProgressBar($, data){
    	$('#uploadForm').find('input').attr('disabled','disabled');
    	$('#spanFile').button("disable")
    	$('#spanFileCancel').button("disable")
    	var percent = parseInt(data.loaded / data.total * 100, 10);
		var progressbarArea = $("#progressBarArea");
		var progressbar = $("#progressBar");
		progressbar.progressbar({ value: data.loaded, max: data.total});
        progressbarArea.find('p.progressBarInitMsg').hide();
       	progressbarArea.find('p.progressBarProgressMsg').show();
   		progressbarArea.find('p.progressBarCompleteMsg').hide();
       	progressbarArea.find('span.bytesRead').html(data.loaded);
       	progressbarArea.find('span.bytesTotal').html(data.total);
       	progressbarArea.find('span.percent').html(percent);
    }

    function completeProgressBar($, total){
    	var progressbarArea = $("#progressBarArea");
		var progressbar = $("#progressBar");
		progressbar.progressbar({ value: total, max: total});
        progressbarArea.find('p.progressBarInitMsg').hide();
       	progressbarArea.find('p.progressBarProgressMsg').hide();
   		progressbarArea.find('p.progressBarCompleteMsg').show();
       	progressbarArea.find('span.bytesTotal').html(total);
    }

    function monitorProgressJSON($){
		$.ajax({
			cache: false,
	        url: '<%= request.getContextPath() %>/json/uploadProgress'})
	    .done(function(progress) {
	    	var data = {loaded: progress.readBytes, total: progress.totalBytes};
	    	updateProgressBar($, data);
	    	setTimeout(function() {
				monitorProgressJSON($);
			}, 250);
	    });
	}

    function decorateFileInputChangeEvent($) {
    	if ($('#selectedFile').length > 0) {
			$('#selectedFile').html($('#tfile').val().replace(/.*(\/|\\)/, '')).append('&nbsp;');
		}
		else {
			$('<span id="selectedFile">&nbsp;'+$('#tfile').val().replace(/.*(\/|\\)/, '')+'</span>').insertAfter($('#spanFile')).append('&nbsp;');
			var span = $('<span id="spanFileCancel" class="btn btn-danger"><span class="glyphicon glyphicon-ban-circle"></span></span>');
			span.appendTo($('#selectedFile'));
    		span.click(function(e){
    				var parent = $('#spanFile').parent();
    				$('#spanFile').remove();
    				$('#selectedFile').remove();
    				$('<input type="file" name="file" id="tfile">').appendTo(parent);
                    $('#tfile').wrap('<span id="spanFile" class="fileinput-button btn btn-success col-md-2"></span>');
                    $('#spanFile').prepend('&nbsp;&nbsp;<fmt:message key="jsp.submit.choose-file.upload-ajax.button.select-file"/>');
                    $('#spanFile').prepend('<span class="glyphicon glyphicon-folder-open"></span>');
                   	$('#tfile').on('change', function(){
    		    		 decorateFileInputChangeEvent($);
    		    	});
    		});
		}
    }

    function setupAjaxUpload($, data){
    	var progressbarArea = $("#progressBarArea");
    	var progressbar = $("#progressBar");
		progressbar.progressbar({ value: false});
		progressbarArea.find('p.progressBarInitMsg').show();
   		progressbarArea.find('p.progressBarProgressMsg').hide();
   		progressbarArea.find('p.progressBarCompleteMsg').hide();
   		progressbarArea.hide();

        $('#tfile').wrap('<span id="spanFile" class="fileinput-button btn btn-success col-md-2"></span>');
        $('#spanFile').prepend('&nbsp;&nbsp;<fmt:message key="jsp.submit.choose-file.upload-ajax.button.select-file"/>');
        $('#spanFile').prepend('<span class="glyphicon glyphicon-folder-open"></span>');
        $('#tfile').on('change', function(){
            decorateFileInputChangeEvent($);
        });

   		// the skip button should not send any files
   		$('input[name="<%=UploadStep.SUBMIT_SKIP_BUTTON%>"]').on('click', function(){
   			$('#tfile').val('');
   		});
   		$('#uploadForm').append('<input type="hidden" id="ajaxUpload" name="ajaxUpload" value="true" />');
   		// track the upload progress for all the submit buttons other than the skip
   		$('input[type="submit"]').not(":disabled")
   		.on('click', function(e){
   			if ($('#tfile').val() != null && $('#tfile').val() != '') {
   				$('#uploadForm').attr('target','uploadFormIFrame');
   	   			initProgressBar($);
	   			setTimeout(function() {
					monitorProgressJSON($);
				}, 100);
   			}
   			else
  			{
				$('#ajaxUpload').val(false);
   			}
   			$('#uploadFormIFrame').on('load',function(){
   				var resultFile = null;
   				try {
	   				var jsonResult = $.parseJSON($('#uploadFormIFrame').contents().find('body').text());
	   				if (jsonResult.fileSizeLimitExceeded) {
	   					$('#actualSize').html(jsonResult.fileSizeLimitExceeded.actualSize);
	   					$('#limitSize').html(jsonResult.fileSizeLimitExceeded.permittedSize);
	   					$('#fileSizeLimitExceeded').dialog("open");
	   					return true;
   					}
	   				resultFile = jsonResult.files[0];
   				} catch (err) {
   					// a file has been upload, the answer is html isntead of json because
   					// come from a different step. Just ignore the target step and reload
   					// the upload list screen. We need to let the user known that the file
   					// has been uploaded
   					resultFile = new Object();
	   				resultFile.status = null;
   				}

   	    		if (resultFile.status == null || resultFile.status == <%= UploadStep.STATUS_COMPLETE %> ||
   	    				resultFile.status == <%= UploadStep.STATUS_UNKNOWN_FORMAT %>)
   	    		{
   	    			completeProgressBar($, resultFile.size);
   		           	if (resultFile.status == null ||
   		           			resultFile.status == <%= UploadStep.STATUS_COMPLETE %>)
   	           		{
   		           		$('#uploadFormPostAjax').removeAttr('enctype')
   		           			.append('<input type="hidden" name="<%= UploadStep.SUBMIT_UPLOAD_BUTTON %>" value="1">');
   	           		}
   		           	else
   	           		{
   		           		$('#uploadFormPostAjax')
   	           				.append('<input type="hidden" name="submit_format_'+resultFile.bitstreamID+'" value="1">')
   	       					.append('<input type="hidden" name="bitstream_id" value="'+resultFile.bitstreamID+'">');
   	           		}

   		           	$('#uploadFormPostAjax').submit();
   	    		}
   	    		else {
   	    			if (resultFile.status == <%= UploadStep.STATUS_NO_FILES_ERROR %>) {
   	    				$('#fileRequired').dialog("open");
   	    			}
   	    			else if (resultFile.status == <%= UploadStep.STATUS_VIRUS_CHECKER_UNAVAILABLE %>) {
   	    				completeProgressBar($, resultFile.size);
   						$('#virusCheckNA').dialog("open");
   	    			}
   					else if (resultFile.status == <%= UploadStep.STATUS_CONTAINS_VIRUS %>) {
   						completeProgressBar($, resultFile.size);
   						$('#virusFound').dialog("open");
   	    			}
   					else {
   						$('#uploadError').dialog("open");
   					}
   	    		}
   	            });
   		});
    }

	function getParameterByName(name) {
		var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
		return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
	}



	jQuery(document).ready(function($){
		setupAjaxUpload($);

		if (getParameterByName("globus")){
			var endpoint  = getParameterByName("endpoint");
	        var path  = getParameterByName("path");
			var filename = getParameterByName("file\\[0\\]");
			$("#globus").val("globus://" + endpoint + ":" + path + filename);
			$("#globus").show();
		}
		$('#spanGlobus').click(function(){
			var globusWin = window.open("<%= Globus.getTransferPage(endpoint, pathToData)%>", "GlobusOps");
			globusWin.focus();
		});



		$('#uploadError').dialog({modal: true, autoOpen: false, width: 600, buttons: {
			'<fmt:message key="jsp.submit.choose-file.upload-ajax.dialog.close"/>': function() {
				$(this).dialog("close");
				$('#uploadFormPostAjax')
       				.append('<input type="hidden" name="<%= UploadStep.SUBMIT_MORE_BUTTON %>" value="1">');
       			$('#uploadFormPostAjax').submit();
		}
		}});

		$('#fileRequired').dialog({modal: true, autoOpen: false, width: 600, buttons: {
			'<fmt:message key="jsp.submit.choose-file.upload-ajax.dialog.close"/>': function() {
				$(this).dialog("close");
				$('#uploadFormPostAjax')
       				.append('<input type="hidden" name="<%= UploadStep.SUBMIT_MORE_BUTTON %>" value="1">');
       			$('#uploadFormPostAjax').submit();
		}
		}});

		$('#fileSizeLimitExceeded').dialog({modal: true, autoOpen: false, width: 600, buttons: {
			'<fmt:message key="jsp.submit.choose-file.upload-ajax.dialog.close"/>': function() {
				$(this).dialog("close");
				$('#uploadFormPostAjax')
       				.append('<input type="hidden" name="<%= UploadStep.SUBMIT_MORE_BUTTON %>" value="1">');
       			$('#uploadFormPostAjax').submit();
		}
		}});

		$('#virusFound').dialog({modal: true, autoOpen: false, width: 600, buttons: {
			'<fmt:message key="jsp.submit.choose-file.upload-ajax.dialog.close"/>': function() {
				$('#uploadFormPostAjax')
       				.append('<input type="hidden" name="<%= UploadStep.SUBMIT_MORE_BUTTON %>" value="1">');
       			$('#uploadFormPostAjax').submit();
				$(this).dialog("close");
		}
		}});

		$('#virusCheckNA').dialog({modal: true, autoOpen:false, width: 600, buttons: {
			'<fmt:message key="jsp.submit.choose-file.upload-ajax.dialog.close"/>': function() {
				$('#uploadFormPostAjax')
       				.append('<input type="hidden" name="<%= UploadStep.SUBMIT_MORE_BUTTON %>" value="1">');
       			$('#uploadFormPostAjax').submit();
				$(this).dialog("close");
			}
		}});
	});
    </script>
    <% } %>
</c:set>
<%  } %>

<dspace:layout style="submission"
			   locbar="off"
               navbar="off"
               titlekey="jsp.submit.choose-file.title"
               nocache="true">
<% if (ajaxProgress) { %>
	<div style="display:none;" id="uploadError" title="<fmt:message key="jsp.submit.upload-error.title" />">
		<p><fmt:message key="jsp.submit.upload-error.info" /></p>
	</div>
	<div style="display:none;" id="fileRequired" title="<fmt:message key="jsp.submit.choose-file.upload-ajax.fileRequired.title" />">
		<p><fmt:message key="jsp.submit.choose-file.upload-ajax.fileRequired.info" /></p>
	</div>
	<div style="display:none;" id="fileSizeLimitExceeded" title="<fmt:message key="jsp.error.exceeded-size.title" />">
		<p><fmt:message key="jsp.error.exceeded-size.text1">
		<fmt:param><span id="actualSize">&nbsp;</span></fmt:param>
		<fmt:param><span id="limitSize">&nbsp;</span></fmt:param>
		</fmt:message></p>
	</div>
	<div style="display:none;" id="virusFound" title="<fmt:message key="jsp.submit.upload-error.title" />">
		<p><fmt:message key="jsp.submit.virus-error.info" /></p>
	</div>
	<div style="display:none;" id="virusCheckNA" title="<fmt:message key="jsp.submit.upload-error.title" />">
		<p><fmt:message key="jsp.submit.virus-checker-error.info" /></p>
	</div>
    <form style="display:none;" id="uploadFormPostAjax" method="post" action="<%= request.getContextPath() %>/submit"
    	enctype="multipart/form-data" onkeydown="return disableEnterKey(event);">
    <%= SubmissionController.getSubmissionParameters(context, request) %>
    </form>
    <iframe id="uploadFormIFrame" name="uploadFormIFrame" style="display: none"> </iframe>
<% } %>
    <form id="uploadForm" <%= bSherpa?"class=\"sherpa col-md-8\"":"" %> method="post"
    	action="<%= request.getContextPath() %>/submit" enctype="multipart/form-data"
    	onkeydown="return disableEnterKey(event);">

		<jsp:include page="/submit/progressbar.jsp"/>


		<%-- Hidden fields needed for SubmissionController servlet to know which step is next--%>
        <%= SubmissionController.getSubmissionParameters(context, request) %>

        <%-- <h1>Submit: Upload a File</h1> --%>
		<h1><fmt:message key="jsp.submit.choose-file.heading"/>
			<dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.index\") + \"#upload\"%>"><fmt:message key="jsp.morehelp"/></dspace:popup>
		</h1>

        <%-- <p>Please enter the name of
        <%= (si.submission.hasMultipleFiles() ? "one of the files" : "the file" ) %> on your
        local hard drive corresponding to your item.  If you click "Browse...", a
        new window will appear in which you can locate and select the file on your
        local hard drive.</p> --%>

		<p><fmt:message key="jsp.submit.choose-file.info1"/></p>

        <%-- FIXME: Collection-specific stuff should go here? --%>
        <%-- <p class="submitFormHelp">Please also note that the DSpace system is
        able to preserve the content of certain types of files better than other
        types.
        <dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.formats\")%>">Information about file types</dspace:popup> and levels of
        support for each are available.</p> --%>

		<div class="submitFormHelp"><fmt:message key="jsp.submit.choose-file.info6"/>
        <dspace:popup page="<%= LocaleSupport.getLocalizedMessage(pageContext, \"help.formats\")%>"><fmt:message key="jsp.submit.choose-file.info7"/></dspace:popup>
        </div>
		<br/>


	   <div class="row container">
		<!-- Globus Dataset Assembly -->
    		<div class="row">
			 <label class="col-md-<%= bSherpa?"4":"4" %>" for="tglobus">&nbsp;</label>

			<span id="spanGlobus" class="fileinput-button btn btn-success col-md-2">
				<span class="glyphicon glyphicon-folder-open"></span>
  					&nbsp;Assemble Dataset
				<input id="tglobus" type="button" name="globus_button">
			</span>
			<input type="text" name="globus" id="globus" size=100 style="display: none;">
		</div><br />

	<!--  Display any outstanding transfers first -->

	<dspace:transferlist activeheader="Transfers initiated to assemble dataset:" inactiveheader="No transfers in progress"/>

<br/>
<% if (ajaxProgress)
{
%>
       <div id="progressBarArea" class="row">
               <div id="progressBar"></div>
               <p class="progressBarInitMsg">
               			<fmt:message key="jsp.submit.choose-file.upload-ajax.uploadInit"/>
               	</p>
               <p class="progressBarProgressMsg" style="display: none;">
                       <fmt:message key="jsp.submit.choose-file.upload-ajax.uploadInProgress">
                               <fmt:param><span class="percent">&nbsp;</span></fmt:param>
                               <fmt:param><span class="bytesRead">&nbsp;</span></fmt:param>
                               <fmt:param><span class="bytesTotal">&nbsp;</span></fmt:param>
                       </fmt:message></p>
               <p class="progressBarCompleteMsg" style="display: none;">
                       <fmt:message key="jsp.submit.choose-file.upload-ajax.uploadCompleted">
                               <fmt:param><span class="bytesTotal">&nbsp;</span></fmt:param>
                       </fmt:message></p>
       </div><br/>
<% } %>

<%
    if (subInfo.getSubmissionItem().hasMultipleFiles())
    {
%>
<%-- Not relevant for Globus --%>
<%
    }
%>

<%
    if (withEmbargo)
    {
%>
        <br/>
        <dspace:access-setting subInfo="<%= subInfo %>" dso="<%= subInfo.getSubmissionItem().getItem() %>" hidden="true" />
        <br/>
<%
    }
%></div>
	<br/>
		<%-- Hidden fields needed for SubmissionController servlet to know which step is next--%>
        <%= SubmissionController.getSubmissionParameters(context, request) %>
        <%
        	int col = 0;
			if(!SubmissionController.isFirstStep(request, subInfo))
			{
				col++;
			}
			if (!fileRequired || subInfo.getSubmissionItem().getItem().hasUploadedFiles())
            {
				col++;
            }
        %>
        <%
		if(!(SubmissionController.isFirstStep(request, subInfo)))
		{ %>
			<div class="col-md-6 pull-right btn-group">
				<input class="btn btn-default col-md-4" type="submit" name="<%=AbstractProcessingStep.PREVIOUS_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.previous"/>" />
				<input class="btn btn-default col-md-4" type="submit" name="<%=AbstractProcessingStep.CANCEL_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.cancelsave"/>"/>
				<input class="btn btn-primary col-md-4" type="submit" name="<%=AbstractProcessingStep.NEXT_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.next"/>"/>
			</div>
    <%  } else { %>
    		<div class="col-md-4 pull-right btn-group">
                <input class="btn btn-default col-md-6" type="submit" name="<%=AbstractProcessingStep.CANCEL_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.cancelsave"/>"/>
				<input class="btn btn-primary col-md-6" type="submit" name="<%=AbstractProcessingStep.NEXT_BUTTON%>" value="<fmt:message key="jsp.submit.edit-metadata.next"/>"/>
			</div>
    <%  }  %>
    </form>
<%
  if (bSherpa)
      {
%>
<div class="col-md-4">
  <div id="sherpaBox" class="panel panel-info">
  	  <div class="panel-heading">
  		  <span id="ui-id-1"><fmt:message key="jsp.sherpa.title" /></span>
  	  </div>
	  <div id="sherpaContent" class="panel-body">
	  <fmt:message key="jsp.sherpa.loading">
			<fmt:param value="<%=request.getContextPath()%>" />
	  </fmt:message>
	  </div>
  </div>
</div>
<%
    }
%>
</dspace:layout>
