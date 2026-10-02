<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><c:out value="${pageTitle != null ? pageTitle : 'SkyBook'}"/> — SkyBook</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-skybook navbar-dark">
    <div class="container">
        <a class="navbar-brand" href="${pageContext.request.contextPath}/">SkyBook<span style="color:#febb02">.</span></a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="nav">
            <c:choose>
                <c:when test="${sessionScope.user != null}">
                    <c:set var="role" value="${sessionScope.user.role}"/>
                    <ul class="navbar-nav me-auto">
                        <c:if test="${role == 'PASSENGER'}">
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/passenger/dashboard">Flights</a></li>
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/passenger/stays">Stays</a></li>
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/passenger/stays?view=mine">My Stays</a></li>
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/passenger/bookings">My Bookings</a></li>
                        </c:if>
                        <c:if test="${role == 'AIRLINE'}">
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/airline/dashboard">Dashboard</a></li>
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/airline/flights/add">Add Flight</a></li>
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/airline/bookings">Bookings</a></li>
                        </c:if>
                        <c:if test="${role == 'ADMIN'}">
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/admin/dashboard">Airlines</a></li>
                            <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/admin/aircraft/add">Add Aircraft</a></li>
                        </c:if>
                    </ul>
                    <span class="navbar-text me-3">
                        <span class="badge badge-role">${role}</span>
                        <c:out value="${sessionScope.user.username}"/>
                    </span>
                    <a class="btn btn-outline-light btn-sm" href="${pageContext.request.contextPath}/logout">Logout</a>
                </c:when>
                <c:otherwise>
                    <ul class="navbar-nav ms-auto">
                        <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/login">Login</a></li>
                        <li class="nav-item"><a class="nav-link" href="${pageContext.request.contextPath}/register">Register</a></li>
                    </ul>
                </c:otherwise>
            </c:choose>
        </div>
    </div>
</nav>

<c:if test="${!fullPage}"><div class="container my-4"></c:if>
<div class="${fullPage ? 'container mt-3' : ''}">
    <c:if test="${not empty errorMessage}">
        <div class="alert alert-danger"><c:out value="${errorMessage}"/></div>
    </c:if>
    <c:if test="${not empty successMessage}">
        <div class="alert alert-success"><c:out value="${successMessage}"/></div>
    </c:if>
</div>
