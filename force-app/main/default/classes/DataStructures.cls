public class DataStructures {
  public class Queue {
    QueueNode first, last;

    public void enqueue(Object obj) {
      QueueNode tmp = new QueueNode(obj);
      if (last != null) {
        last.next = tmp;
      }
      last = tmp;
      if (first == null) {
        first = last;
      }
    }
    public Object dequeue() {
      if (first == null) {
        throw new QueueException('Queue is Empty');
      }
      Object objToReturn = first.data;
      first = first.next;
      if (first == null) {
        last = null;
      }
      return objToReturn;
    }
    public Object peek() {
      if (first == null) {
        throw new QueueException('Queue is Empty');
      }
      return first.data;
    }
    public Boolean isEmpty() {
      return first == null;
    }
  }

  class QueueNode {
    Object data;
    QueueNode next;

    QueueNode(Object data) {
      this.data = data;
    }
  }

  public class QueueException extends Exception {
  }
}