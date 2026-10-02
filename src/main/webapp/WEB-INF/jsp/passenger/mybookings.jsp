<%@ include file="../common/header.jsp" %>

<h4 class="mb-3">My Bookings</h4>

<c:if test="${empty bookings}">
    <div class="card card-skybook p-4">No bookings yet. <a href="${pageContext.request.contextPath}/passenger/dashboard">Search a flight</a> to get started.</div>
</c:if>

<c:forEach var="b" items="${bookings}">
    <div class="card card-skybook p-3 mb-3">
        <div class="row align-items-center">
            <div class="col-md-5">
                <div class="fw-bold">${b.flightInfo}</div>
                <div class="text-muted small">Booking #${b.bookingId} &middot; ${b.bookingDateFormatted}</div>
            </div>
            <div class="col-md-3">
                <span class="status-pill status-${b.status}">${b.status}</span>
            </div>
            <div class="col-md-4 text-end">
                <a class="btn btn-sm btn-outline-primary" href="${pageContext.request.contextPath}/passenger/ticket?bookingId=${b.bookingId}">View Ticket</a>
                <c:if test="${b.status == 'Confirmed'}">
                    <form method="post" action="${pageContext.request.contextPath}/passenger/cancel" style="display:inline"
                          onsubmit="return confirm('Cancel this booking?');">
                        <input type="hidden" name="bookingId" value="${b.bookingId}">
                        <button class="btn btn-sm btn-outline-danger" type="submit">Cancel</button>
                    </form>
                </c:if>
            </div>
        </div>
    </div>
</c:forEach>

<%@ include file="../common/footer.jsp" %>
