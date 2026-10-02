<%@ include file="../common/header.jsp" %>
<h3 class="mb-3">My stays</h3>
<c:if test="${empty stays}"><p class="text-muted">No stays booked yet.</p></c:if>
<c:forEach var="s" items="${stays}">
  <div class="flight-card"><div class="fc-main"><h5>${s.HotelName}, ${s.City}</h5>
    <div class="fc-sub">${s.CheckIn} &rarr; ${s.CheckOut} &middot; ${s.Guests} guest(s) &middot; ${s.Rooms} room(s)</div></div>
    <div class="fc-side"><span class="status-pill status-${s.Status}">${s.Status}</span>
      <div class="text-end"><div class="fc-price">INR<fmt:formatNumber value="${s.TotalPrice}" maxFractionDigits="0"/></div>
      <c:if test="${s.Status == 'Confirmed'}"><form method="post" action="${pageContext.request.contextPath}/passenger/stays"><input type="hidden" name="cancelId" value="${s.StayID}"><button class="btn-view mt-2">Cancel</button></form></c:if></div></div></div>
</c:forEach>
<%@ include file="../common/footer.jsp" %>
