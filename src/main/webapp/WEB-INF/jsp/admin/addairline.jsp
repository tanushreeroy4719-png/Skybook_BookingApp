<%@ include file="../common/header.jsp" %>

<div class="card card-skybook p-4">
    <h4 class="mb-3">Register a New Airline</h4>
    <form method="post" action="${pageContext.request.contextPath}/admin/airlines/add" class="row g-3">
        <div class="col-md-6">
            <label class="form-label">Login Username *</label>
            <input class="form-control" name="username" required>
        </div>
        <div class="col-md-6">
            <label class="form-label">Login Password</label>
            <input class="form-control" value="airline@123" readonly disabled>
            <div class="form-text">All airline accounts use this fixed password.</div>
        </div>
        <div class="col-md-6">
            <label class="form-label">Airline Name *</label>
            <input class="form-control" name="airlineName" required>
        </div>
        <div class="col-md-3">
            <label class="form-label">IATA Code *</label>
            <input class="form-control" name="iataCode" maxlength="2" style="text-transform:uppercase" required>
        </div>
        <div class="col-md-3">
            <label class="form-label">Country *</label>
            <input class="form-control" name="country" required>
        </div>
        <div class="col-md-6">
            <label class="form-label">Contact Email *</label>
            <input class="form-control" type="email" name="email" required>
        </div>
        <div class="col-12">
            <button class="btn btn-sb-primary" type="submit">Register Airline</button>
            <a class="btn btn-outline-secondary" href="${pageContext.request.contextPath}/admin/dashboard">Cancel</a>
        </div>
    </form>
</div>

<%@ include file="../common/footer.jsp" %>
