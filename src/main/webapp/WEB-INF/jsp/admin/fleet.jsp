<%@ include file="../common/header.jsp" %>

<h4 class="mb-3">Fleet — ${airline.airlineName} (${airline.iataCode})</h4>

<c:if test="${empty fleet}">
    <div class="card card-skybook p-4">No aircraft yet for this airline.</div>
</c:if>

<c:if test="${not empty fleet}">
    <div class="table-responsive">
        <table class="table bg-white card-skybook">
            <thead><tr><th>ID</th><th>Registration</th><th>Model</th><th>Seats</th><th>Status</th><th>Year</th></tr></thead>
            <tbody>
            <c:forEach var="ac" items="${fleet}">
                <tr>
                    <td>${ac.aircraftId}</td>
                    <td>${ac.registrationNo}</td>
                    <td>${ac.aircraftModel}</td>
                    <td>${ac.totalSeats}</td>
                    <td>${ac.status}</td>
                    <td>${ac.manufactureYear > 0 ? ac.manufactureYear : '—'}</td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </div>
</c:if>

<a class="btn btn-outline-secondary" href="${pageContext.request.contextPath}/admin/dashboard">Back to Airlines</a>

<%@ include file="../common/footer.jsp" %>
