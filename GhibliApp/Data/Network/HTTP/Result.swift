public enum Result<T> {
	case success(T)
	case failure(HTTPError)
}
