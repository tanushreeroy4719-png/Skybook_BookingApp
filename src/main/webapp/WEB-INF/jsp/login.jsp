<%@ include file="common/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-5">
        <div class="card card-skybook p-4">
            <h4 class="mb-3">Login</h4>
            <form method="post" action="${pageContext.request.contextPath}/login">
                <c:if test="${not empty param.next}">
                    <input type="hidden" name="next" value="${param.next}">
                </c:if>
                <div class="mb-3">
                    <label class="form-label">Username</label>
                    <input class="form-control" type="text" name="username" value="${username}" required autofocus>
                </div>
                <div class="mb-3">
                    <label class="form-label">Password</label>
                    <input class="form-control" type="password" name="password" required>
                </div>
                <button class="btn btn-sb-primary w-100" type="submit">Login</button>
            </form>
            <hr>
            <p class="text-muted small mb-0">
                Default admin login: <code>admin</code> / <code>admin123</code>
            </p>
            <p class="text-muted small mb-0">
                Airline accounts: password is <code>airline@123</code>
            </p>
            <p class="mt-2 mb-0">New passenger? <a href="${pageContext.request.contextPath}/register">Create an account</a></p>
        </div>
    </div>
</div>

<%@ include file="common/footer.jsp" %>
