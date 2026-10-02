<%@ include file="common/header.jsp" %>

<div class="row justify-content-center">
    <div class="col-md-7">
        <div class="card card-skybook p-4">
            <h4 class="mb-3">Create your SkyBook account</h4>
            <form method="post" action="${pageContext.request.contextPath}/register">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">Username *</label>
                        <input class="form-control" name="username" value="${username}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Password *</label>
                        <input class="form-control" type="password" name="password" required
                               pattern="[A-Za-z]{2,}@[0-9]{3,}"
                               title="Letters, then @, then numbers, e.g. tanu@123"
                               placeholder="e.g. tanu@123">
                        <div class="form-text">Format: <code>name@123</code> &ndash; letters, then <code>@</code>, then numbers.</div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">First Name *</label>
                        <input class="form-control" name="firstName" value="${firstName}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Last Name</label>
                        <input class="form-control" name="lastName" value="${lastName}">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Email *</label>
                        <input class="form-control" type="email" name="email" value="${email}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Contact No</label>
                        <input class="form-control" name="contactNo" value="${contactNo}">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Date of Birth *</label>
                        <input class="form-control" type="date" name="dob" value="${dob}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Passport Number</label>
                        <input class="form-control" name="passport" value="${passport}">
                    </div>
                </div>
                <button class="btn btn-sb-primary mt-4" type="submit">Create Account</button>
            </form>
            <p class="mt-3 mb-0">Already have an account? <a href="${pageContext.request.contextPath}/login">Login</a></p>
        </div>
    </div>
</div>

<%@ include file="common/footer.jsp" %>
