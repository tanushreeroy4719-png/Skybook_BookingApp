<%@ page contentType="text/html;charset=UTF-8" isErrorPage="true" %>
<% request.setAttribute("pageTitle", "Error"); %>
<%@ include file="common/header.jsp" %>

<div class="card card-skybook p-4">
    <h4 class="text-danger">Something went wrong</h4>
    <p class="mb-0">
        <c:choose>
            <c:when test="${not empty errorMessage}">${errorMessage}</c:when>
            <c:when test="${not empty exception}">${exception.message}</c:when>
            <c:otherwise>An unexpected error occurred.</c:otherwise>
        </c:choose>
    </p>
    <a href="${pageContext.request.contextPath}/" class="btn btn-sb-primary mt-3" style="width:fit-content">Back to home</a>
</div>

<%@ include file="common/footer.jsp" %>
