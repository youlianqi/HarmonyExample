
import Socket from '@ohos.net.socket';
import connection from '@ohos.net.connection';
import { BusinessError } from '@ohos.base';
import TALogicManager from '../ta/TALogicManager';
import assertUndefined from '@ohos/hypium/src/main/module/assert/assertUndefined';

const TAG: string = '[Demo][Ta]';

export default class TACore {
  public taLogicManager: TALogicManager = new TALogicManager();
  private socket: Socket.TCPSocketServer = Socket.constructTCPSocketServerInstance();
  private address: connection.NetAddress = {
    address: "0.0.0.0",
    port: 50001
  };

  // 定义存放客户端连接的数组
  private tcpConnectArray: Socket.TCPSocketConnection[] = [];

  public startServer(): boolean {

    this.socket.listen(this.address, (err: BusinessError) => {

      if (err) {
        console.info(TAG, "listen fail");
        return;
      }
      console.info(TAG, "listen success");
    })

    class SocketInfo {
      message: ArrayBuffer = new ArrayBuffer(1);
      remoteInfo: Socket.SocketRemoteInfo = {} as Socket.SocketRemoteInfo;
    }

    this.socket.on('connect', (client: Socket.TCPSocketConnection) => {
      console.info(TAG, "socket on connect")

      // 保存客户端的socket
      this.tcpConnectArray.push(client);

      client.on("close", () => {
        console.info(TAG, "socket on close")
      });

      setTimeout(() => {
        client.off("message");
        client.off("close");
      }, 30 * 1000);

      client.on("message", (value: SocketInfo) => {

        console.info(TAG, "socket on message");

        let buffer = value.message;
        let dataView = new DataView(buffer);
        let str = "";
        for (let i = 0; i < dataView.byteLength; ++i) {
          str += String.fromCharCode(dataView.getUint8(i));
        }
        console.info(TAG, "on message connect received:" + str);

        let response: string = this.taLogicManager.execCommand(str)
        let tcpSendOptions : Socket.TCPSendOptions = {} as Socket.TCPSendOptions;
        tcpSendOptions.data = response;
        console.info(TAG, "on message connect send:" + tcpSendOptions.data );
        client.send(tcpSendOptions, (err: BusinessError) => {
          if (err) {
            console.info(TAG, "send fail err:" + err.code);
            return;
          }
          console.info(TAG, "send success");
        })
      });
    });

    this.socket.off('connect', () => {
      console.info(TAG, "socket off connect success")
    });

    setTimeout(() => {
      this.socket.off("connect");
    }, 30 * 1000);

    return true
  }

  public stopServer(): void {
  }

  public execCommand(jsonString: string): string {
    let response = this.taLogicManager.execCommand(jsonString)
    return response
  }
}
