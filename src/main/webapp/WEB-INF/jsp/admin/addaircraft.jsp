<%@ include file="../common/header.jsp" %>

<div class="card card-skybook p-4">
    <h4 class="mb-3">Add Aircraft</h4>
    <c:if test="${empty airlines}">
        <div class="alert alert-warning">No airlines registered yet — <a href="${pageContext.request.contextPath}/admin/airlines/add">register one first</a>.</div>
    </c:if>
    <c:if test="${not empty airlines}">
        <form method="post" action="${pageContext.request.contextPath}/admin/aircraft/add" class="row g-3">
            <div class="col-md-6">
                <label class="form-label">Airline *</label>
                <select class="form-select" name="airlineId" required>
                    <c:forEach var="a" items="${airlines}">
                        <option value="${a.airlineId}">${a.airlineName} (${a.iataCode})</option>
                    </c:forEach>
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label">Registration No *</label>
                <input class="form-control" name="registrationNo" placeholder="e.g. VT-ABC" required>
            </div>
            <div class="col-md-6">
                <label class="form-label">Aircraft Model *</label>
                <input class="form-control" name="aircraftModel" placeholder="e.g. Airbus A320" required>
            </div>
            <div class="col-md-3">
                <label class="form-label">Total Seats *</label>
                <input class="form-control" type="number" name="totalSeats" min="1" required>
            </div>
            <div class="col-md-3">
                <label class="form-label">Manufacture Year</label>
                <input class="form-control" type="number" name="manufactureYear" min="1950" max="2100">
            </div>
            <div class="col-md-6">
                <label class="form-label">Status *</label>
                <select class="form-select" name="status" required>
                    <option value="Active">Active</option>
                    <option value="Grounded">Grounded</option>
                    <option value="Retired">Retired</option>
                </select>
            </div>
            <div class="col-12">
                <button class="btn btn-sb-primary" type="submit">Add Aircraft</button>
                <a class="btn btn-outline-secondary" href="${pageContext.request.contextPath}/admin/dashboard">Cancel</a>
            </div>
            <p class="text-muted small mb-0">The full seat map (with window/aisle/middle surcharges based on the airline's tier) is generated automatically.</p>
        </form>
    </c:if>
</div>

<%@ include file="../common/footer.jsp" %>
