<%@ include file="../common/header.jsp" %>

<div class="d-flex justify-content-between align-items-center mb-3">
    <h4 class="mb-0">Airlines</h4>
    <div>
        <a class="btn btn-sb-accent btn-sm" href="${pageContext.request.contextPath}/admin/airlines/add">+ Register Airline</a>
        <a class="btn btn-outline-primary btn-sm" href="${pageContext.request.contextPath}/admin/aircraft/add">+ Add Aircraft</a>
    </div>
</div>

<c:if test="${empty airlines}">
    <div class="card card-skybook p-4">No airlines registered yet.</div>
</c:if>

<c:if test="${not empty airlines}">
    <div class="table-responsive">
        <table class="table bg-white card-skybook">
            <thead><tr><th>ID</th><th>Name</th><th>IATA</th><th>Country</th><th>Email</th><th>Status</th><th></th></tr></thead>
            <tbody>
            <c:forEach var="a" items="${airlines}">
                <tr>
                    <td>${a.airlineId}</td>
                    <td>${a.airlineName}</td>
                    <td>${a.iataCode}</td>
                    <td>${a.country}</td>
                    <td>${a.contactEmail}</td>
                    <td><span class="status-pill ${a.active ? 'status-Confirmed' : 'status-Cancelled'}">${a.active ? 'Active' : 'Inactive'}</span></td>
                    <td class="text-end">
                        <a class="btn btn-sm btn-outline-secondary" href="${pageContext.request.contextPath}/admin/fleet?airlineId=${a.airlineId}">Fleet</a>
                    </td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
    <p class="text-muted small">To deactivate an airline, use its login username (ask them, or check your records) —
        <a href="#" data-bs-toggle="modal" data-bs-target="#deactModal">deactivate by username</a>.</p>
</c:if>

<!-- Simple deactivate-by-username form, since the console app keys deactivation off the login username -->
<div class="modal fade" id="deactModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="post" action="${pageContext.request.contextPath}/admin/airlines/deactivate">
                <div class="modal-header"><h5 class="modal-title">Deactivate Airline</h5></div>
                <div class="modal-body">
                    <label class="form-label">Airline login username</label>
                    <input class="form-control" name="username" required>
                </div>
                <div class="modal-footer">
                    <button type="submit" class="btn btn-sb-primary">Deactivate</button>
                </div>
            </form>
        </div>
    </div>
</div>

<%@ include file="../common/footer.jsp" %>
